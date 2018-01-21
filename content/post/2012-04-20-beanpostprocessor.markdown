---
categories:
- article
- reflection
- java
- logging
- spring
- разработка
- development
date: 2012-04-20T15:51:00Z
title: Использование BeanPostProcessor на примере журналирования
url: /2012/04/20/beanpostprocessor/
---

Сегодня я хочу рассказать, как можно сделать инициализацию логгера в классе с использованием аннотаций и <a href="http://static.springsource.org/spring/docs/current/javadoc-api/org/springframework/beans/factory/config/BeanPostProcessor.html">BeanPostProcessor</a>

Очень часто мы инициализируем логгер следующим образом:

```java
public class MyClass {
    private static final Logger LOG = LoggerFactory.getLogger(MyClass.class);
}
```

Я покажу, как сделать, чтобы можно было писать вот так: 

```java
@Log
private Logger LOG;
```

Первым делом нам нужно объявить аннотацию:

```java
@Retention(RUNTIME)
@Target(FIELD)
@Documented
public @interface Log {
    String category() default "";
}
```

А вторым делом, написать собственный <tt>BeanPostProcessor</tt>, который бы устанавливал нам логгер:

```java
import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.config.BeanPostProcessor;
import org.springframework.stereotype.Component;
import org.springframework.util.ReflectionUtils;

@Component
public class LoggerPostProcessor implements BeanPostProcessor {
    @Override
    public Object postProcessAfterInitialization(Object bean, String beanName) {
        return bean;
    }

    @Override
    public Object postProcessBeforeInitialization(final Object bean, final String beanName) {
        ReflectionUtils.doWithFields(bean.getClass(), new FieldProcessor(bean, beanName), new LoggerFieldFilter());
        return bean;
    }

    private static class FieldProcessor implements ReflectionUtils.FieldCallback {
        private final Object bean;
        private final String beanName;

        private FieldProcessor(Object bean, String beanName) {
            this.bean = bean;
            this.beanName = beanName;
        }

        @Override
        public void doWith(Field field) throws IllegalAccessException {
            Log loggerAnnot = field.getAnnotation(Log.class);

            // Sanity check if annotation is on the field with correct type.
            if (field.getType().equals(org.slf4j.Logger.class)) {
                // As user can override logger category - check if it was done.
                String loggerCategory = loggerAnnot.category();
                if (StringUtils.isBlank(loggerCategory)) {
                    // use default category instead.
                    loggerCategory = bean.getClass().getName();
                }
                Logger logger = LoggerFactory.getLogger(loggerCategory);
                ReflectionUtils.makeAccessible(field);
                field.set(bean, logger);
            } else {
                throw new IllegalArgumentException(
                    "Unable to set logger on field '" + field.getName() + "' in bean '" + beanName +
                        "': field should have class " + Logger.class.getName());
            }
        }
    }

    private static class LoggerFieldFilter implements ReflectionUtils.FieldFilter {
        @Override
        public boolean matches(Field field) {
            Log logger = field.getAnnotation(Log.class);
            return null != logger;
        }
    }
}
```

Если вы используете не <a href="http://www.slf4j.org/">sfl4j</a>, а, например, <a href="http://logging.apache.org/log4j/1.2/">log4j</a>, или <a href="http://commons.apache.org/logging/">commons-logging</a>, то нужно немного поправить код внутри метода <tt>doWith</tt>

Попутно, данный код показывает пример использования класса <a href="http://static.springsource.org/spring/docs/current/javadoc-api/org/springframework/util/ReflectionUtils.html">org.springframework.util.ReflectionUtils</a>.
