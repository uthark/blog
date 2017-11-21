---
categories:
- article
- development
- spring data
- jpa
date: 2012-04-24T14:04:00Z
title: Ищем с помощью Spring Data JPA
url: /2012/04/24/spring-data-jpa/
---

Рассмотрим подробнее одну из наиболее полезных вещей в Spring Data JPA - генерация JPQL-запросов на основе имени метода.


Spring Data JPA умеет автоматически генерировать запросы используя для подсказки название метода.

Например, метод `User.findByLoginAndPassword` сгенерирует примерно следующий код:

```sql
FROM User u where u.login = :login and password = :password
```

Вообще Spring Data JPA пытается быть умным, поэтому реализация <tt>findBy{...}</tt> методов ищется следующим образом:

<ol>
<li>Сначала смотрится аннотация <a href="http://static.springsource.org/spring-data/data-jpa/docs/current/api/org/springframework/data/jpa/repository/Query.html">@Query</a> на объявлении метода, если она есть, то используется.</li>
<li>Затем смотрится аннотация <a href="http://docs.oracle.com/javaee/5/api/javax/persistence/NamedQuery.html">@NamedQuery</a> с именем вида <tt>Entity.findMethodName</tt>, для вышеприведённого случая это будет <tt>User.findByLoginAndPassword</tt>. </li>
<li>Если ничего не нашли. то по сигнатуре метода <a href="https://github.com/SpringSource/spring-data-jpa/blob/master/src/main/java/org/springframework/data/jpa/repository/query/JpaQueryCreator.java">генерируется запрос</a>.</li>
</ol>

У <tt>@Query</tt> следующие плюсы:
<ol>
<li>Позволяет не засорять объявление доменной сущности.</li>
<li>Сильно помогает, если у нас в запросе есть неявные джойны, потому что для таких запросов Spring Data JPA <a href="https://jira.springsource.org/browse/DATAJPA-35">не умеет корректно генерировать</a> запрос <tt>SELECT COUNT(*)</tt>, который нужен в тех случаях, когда метод должен вернуть <a href="http://static.springsource.org/spring-data/data-commons/docs/current/api/org/springframework/data/domain/Page.html">Page</a>. </li>
</ol>

Очевидно, что при использовании запросов нам необходимо каким-то образом указывать параметры для запросов. Для этого есть аннотация <a href="http://static.springsource.org/spring-data/data-commons/docs/current/api/org/springframework/data/repository/query/Param.html">@Param</a>:

```java
@Query("select u from User u where u.login = :login and u.password = :password")
Page<User> findByLoginAndPassword(@Param("login") String login, @Param("password") String password);
```

Кроме того, Spring Data JPA поддерживает отличную <a href="http://www.martinfowler.com/apsupp/spec.pdf">концепцию спецификаций</a>.

Спецификации позволяют делать составлять сложные запросы из набора простых.

Для поддержки спецификаций необходимо объявить метод в репозитории:

```java
Page<User> findAll(Specification<User> spec, Pageable pageable);
```

Спецификация по сути является фильтром и позволяет комбинирование фильтров, что даёт мощный инструмент для построения запросов.

Пример использования спецификаций:

Объявляем наши спецификации:
```java
public static Specification<User> firstNameOrLastNameOrLoginLike(final String search) {
    return new Specification<User>() {
        @Override
        public Predicate toPredicate(Root<User> root, CriteriaQuery<?> query, CriteriaBuilder builder) {

            Predicate loginPredicate = builder.like(root.get(User_.login), search);
            Predicate firstnamePredicate = builder.like(root.get(User_.firstname), search);
            Predicate lastnamePredicate = builder.like(root.get(User_.lastname), search);

            return builder.or(loginPredicate, firstnamePredicate, lastnamePredicate);
        }
    };
}

public static Specification<User> hasRole(final Role role) {
    return new Specification<User>() {
        @Override
        public Predicate toPredicate(Root<User> root, CriteriaQuery<?> query, CriteriaBuilder builder) {
            return builder.equal(root.get(User_.role), role);
        }
    };
}
```

И в нашем сервисе комбинируем их:

```java
public Page<User> searchUser(Role role, String search, Pageable pageable) {
    Specifications<User> mainSpec = where(hasRole(role));

    // уточняем запрос, если была передана строка для поиска
    if (StringUtils.isNotBlank(search)) {
        mainSpec = mainSpec.and(firstNameOrLastNameOrLoginLike(search));
    } 

    return userRepository.findAll(mainSpec, pageable);
}
```
