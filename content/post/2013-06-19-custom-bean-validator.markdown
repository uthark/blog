---
categories:
- article
- beanvalidation
- validator
- validation
- development
comments: true
date: 2013-06-19T00:00:00Z
published: true
sharing: true
title: Пишем валидатор для Bean Validation API
url: /2013/06/19/custom-bean-validator/
---

[JSR-303](http://jcp.org/en/jsr/detail?id=303) предоставляет удобный API для проверки валидности объектов, а также входных параметров. Очевидно, что [стандартных валидаторов](http://docs.oracle.com/javaee/6/tutorial/doc/gircz.html) в какой-то момент может быть недостаточно, поэтому необходимо писать собственный.

Хочу показать на примере валидации запроса к [MongoDB](http://www.mongodb.org/), как легко это делается.

## Создание аннотации

```java
@Target({FIELD, PARAMETER})
@Retention(RUNTIME)
@Documented
@Constraint(validatedBy = {MongoQueryValidator.class})
public @interface MongoQuery {

    String message() default "Invalid mongo query";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
```

Обратите внимание на аннотацию [@Constraint](http://docs.oracle.com/javaee/7/api/javax/validation/Constraint.html) - она описывает, какой класс будет проводить реальную валидацию. Атрибуты `groups()` и `payload()` являются обязательными.

## Написание валидатора

```java
public class MongoQueryValidator implements ConstraintValidator<MongoQuery, CharSequence> {

    @Override
    public void initialize(MongoQuery constraintAnnotation) {
    }

    @Override
    public boolean isValid(CharSequence value, ConstraintValidatorContext context) {
        // ignore null and empty strings.
        if (null == value || value.length() == 0) {
            return true;
        }

        try {
            Query query = new BasicQuery(value.toString());
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
```

В данном случае, валидатор у нас простой - мы пытаемся создать Mongo Query из переданной строки, если это не удаётся, то считаем, что строка не является корректным запросом к Mongo и возвращаем `false`.

Если есть желание возвращать динамическое сообщение об ошибке, то это можно сделать следующим образом:

```java
    context.disableDefaultConstraintViolation();
    context.buildConstraintViolationWithTemplate("<Custom error message>").addConstraintViolation();
```

## Использование
На этом всё, теперь нам остаётся только добавить валидацию на нашу модель или входной параметр.

```java
public class Model {
    @MongoQuery
    private String queryCriteria;

}
```
