---
categories:
- article
- development
- spring
- autowiring
comments: true
date: 2013-06-29T00:00:00Z
published: true
sharing: true
title: Пишем @Enable*-аннотацию для Spring
url: /2013/06/29/spring-enable-annotation/
---

Начиная с версии 3.1 Spring поддерживает декларативное включение необходимой функциональности через, так называемые, `@Enable*` аннотации. Пример таких аннотаций:
[`org.springframework.web.servlet.config.annotation.EnableWebMvc`](http://static.springsource.org/spring/docs/3.2.x/javadoc-api/org/springframework/web/servlet/config/annotation/EnableWebMvc.html), [`org.springframework.cache.annotation.EnableCaching`](http://static.springsource.org/spring/docs/3.2.x/javadoc-api/org/springframework/cache/annotation/EnableCaching.html), [`org.springframework.scheduling.annotation.EnableAsync`](http://static.springsource.org/spring/docs/3.2.x/javadoc-api/org/springframework/scheduling/annotation/EnableAsync.html) и другие.


В продолжение темы [прошлого поста](/blog/2013/06/28/jaxrs-spring-autowiring/), я хочу показать, как можно добавить собственную `@Enable` аннотацию.

Для автоматического создания клиента для REST-ресурса нам необходима следующая информация: 

1. Пакет, в котором искать интерфейсы, проаннотированные аннотацией [`@Path()`](https://jax-rs-spec.java.net/nonav/2.0/apidocs/javax/ws/rs/Path.html)
2. Базовый адрес REST-приложения.

Для того, чтобы передать эту информацию, мы создадим два атрибута в аннотации: `scanPackage()` и `endpoint()`

Кроме того, для обработки аннотации необходимо указать обработчик. Это можно сделать передав подкласс [`org.springframework.context.annotation.ImportBeanDefinitionRegistrar`](http://static.springsource.org/spring-framework/docs/3.2.x/javadoc-api/org/springframework/context/annotation/ImportBeanDefinitionRegistrar.html) через аннотацию [`@Import`](http://static.springsource.org/spring-framework/docs/3.2.x/javadoc-api/org/springframework/context/annotation/Import.html)

Пишем аннотацию:

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@Import(JaxRsRestClientRegistrar.class)
public @interface EnableJaxRsRestClient {

    String scanPackage();

    String endpoint();
}
```


Теперь осталось написать реализацию интерфейса `org.springframework.context.annotation.ImportBeanDefinitionRegistrar`. Так как у нас уже есть написанный ранее [BeanFactoryPostProcessor](http://static.springsource.org/spring-framework/docs/3.2.x/javadoc-api/org/springframework/beans/factory/config/BeanFactoryPostProcessor.html) в виде `RestClientPostProcessor`, реализация интерфейса будет простой - мы создадим описание бина для Spring и зарегистрируем его в реестре бинов. 

```java
public class JaxRsRestClientRegistrar implements ImportBeanDefinitionRegistrar {

    protected static final String PROPERTY_ENDPOINT = "endpoint";

    protected static final String PROPERTY_SCAN_PACKAGE = "basePackage";

    @Override
    public void registerBeanDefinitions(AnnotationMetadata importingClassMetadata, BeanDefinitionRegistry registry) {
        EnableJaxRsRestClient annotation =
                (EnableJaxRsRestClient) ((StandardClassMetadata) importingClassMetadata).getIntrospectedClass()
                        .getAnnotation(EnableJaxRsRestClient.class);
        String scanPackage = annotation.scanPackage();
        String endpoint = annotation.endpoint();

        GenericBeanDefinition beanDefinition = new GenericBeanDefinition();
        beanDefinition.setAbstract(false);
        beanDefinition.setBeanClass(RestClientPostProcessor.class);
        MutablePropertyValues propertyValues = new MutablePropertyValues();
        propertyValues.add(PROPERTY_ENDPOINT, endpoint);
        propertyValues.add(PROPERTY_SCAN_PACKAGE, scanPackage);
        beanDefinition.setPropertyValues(propertyValues);

        registry.registerBeanDefinition(ClassUtils.getShortName(getClass()), beanDefinition);
    }
}
``` 

Теперь мы можем использовать аннотацию:

```java
@Configuration
@EnableJaxRsRestClient(scanPackage = "<base package>", endpoint = "${remote.rest.endpoint}")
class TestAutowiringConfiguration {

    @Bean
    public static PropertyPlaceholderConfigurer configurer() {
        PropertyPlaceholderConfigurer pph = new PropertyPlaceholderConfigurer();
        pph.setLocation(new ClassPathResource("application.properties"));
        return pph;
    }

}
```

Обратите внимание, что endpoint можно передавать с использованием подстановочных свойств.
