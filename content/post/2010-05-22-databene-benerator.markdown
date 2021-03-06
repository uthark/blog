---
categories:
- article
- performance
- testing
- development
date: 2010-05-22T00:26:00Z
title: Создание больших объёмов тестовых данных с помощью Databene Benerator
url: /2010/05/22/databene-benerator/
---

<p>Периодически необходимо решать задачу создания больших ( и не очень) объёмов тестовых данных для проведения различных видов тестирования - функционального, нагрузочного (тестирование стабильности и производительности). При этом часто получается так, что система на тестовых данных ведёт себя совсем иначе, чем на реальных данных. Причина кроется в том, что создать правдоподобные тестовые данные всегда достаточно сложно.</p>
<p>Изучая данный вопрос я наткнулся на замечательный фреймворк - <a href="http://databene.org/databene-benerator">Databene Benerator</a>, основной целью создания которого как раз и является создание правдоподобных тестовых данных для проведения различных видов тестирования.</p>
<h4>Установка</h4>
<p>Установка фреймворка осуществляется двумя способами - как отдельное приложение и как плагин для Maven.</p>
<h5>Установка под Maven</h5>
<p>Для использования Databene benerator в проектах, использующих для сборки Apache Maven необходимо добавить в зависимости databene-benerator и сконфигурировать его.</p>

```xml
&lt;project xmlns=&quot;http://maven.apache.org/POM/4.0.0&quot; xmlns:xsi=&quot;http://www.w3.org/2001/XMLSchema-instance&quot;
         xsi:schemaLocation=&quot;http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd&quot;&gt;
  &lt;modelVersion&gt;4.0.0&lt;/modelVersion&gt;
  &lt;groupId&gt;com.myorganization&lt;/groupId&gt;
  &lt;artifactId&gt;databene-benerator-test&lt;/artifactId&gt;
  &lt;version&gt;1.0&lt;/version&gt;
  &lt;packaging&gt;jar&lt;/packaging&gt;
  &lt;name&gt;data generation project&lt;/name&gt;
  &lt;dependencies&gt;
    &lt;dependency&gt;
      &lt;groupId&gt;org.databene&lt;/groupId&gt;
      &lt;artifactId&gt;databene-benerator&lt;/artifactId&gt;
      &lt;version&gt;0.5.9&lt;/version&gt;
    &lt;/dependency&gt;
    &lt;dependency&gt;
      &lt;groupId&gt;org.databene&lt;/groupId&gt;
      &lt;artifactId&gt;databene-webdecs&lt;/artifactId&gt;
      &lt;version&gt;0.4.9&lt;/version&gt;
    &lt;/dependency&gt;
    &lt;dependency&gt;
      &lt;groupId&gt;org.databene&lt;/groupId&gt;
      &lt;artifactId&gt;databene-commons&lt;/artifactId&gt;
      &lt;version&gt;0.4.9&lt;/version&gt;
    &lt;/dependency&gt;
    &lt;dependency&gt;
      &lt;groupId&gt;mysql&lt;/groupId&gt;
      &lt;artifactId&gt;mysql-connector-java&lt;/artifactId&gt;
      &lt;version&gt;5.1.6&lt;/version&gt;
    &lt;/dependency&gt;
  &lt;/dependencies&gt;
  &lt;build&gt;
    &lt;resources&gt;
      &lt;resource&gt;
        &lt;directory&gt;src/main/resources&lt;/directory&gt;
        &lt;filtering&gt;true&lt;/filtering&gt;
      &lt;/resource&gt;
    &lt;/resources&gt;
    &lt;plugins&gt;
      &lt;plugin&gt;
        &lt;groupId&gt;org.apache.maven.plugins&lt;/groupId&gt;
        &lt;artifactId&gt;maven-compiler-plugin&lt;/artifactId&gt;
        &lt;configuration&gt;
          &lt;encoding&gt;UTF-8&lt;/encoding&gt;
          &lt;source&gt;1.5&lt;/source&gt;
          &lt;target&gt;1.5&lt;/target&gt;
        &lt;/configuration&gt;
      &lt;/plugin&gt;
      &lt;plugin&gt;
        &lt;groupId&gt;org.databene&lt;/groupId&gt;
        &lt;artifactId&gt;maven-benerator-plugin&lt;/artifactId&gt;
        &lt;version&gt;0.5.9&lt;/version&gt;
        &lt;executions&gt;
          &lt;execution&gt;
            &lt;phase&gt;compile&lt;/phase&gt;
            &lt;goals&gt;
              &lt;goal&gt;generate&lt;/goal&gt;
            &lt;/goals&gt;
          &lt;/execution&gt;
        &lt;/executions&gt;
        &lt;configuration&gt;
          &lt;descriptor&gt;src/main/resources/benerator.ben.xml&lt;/descriptor&gt;
          &lt;encoding&gt;UTF-8&lt;/encoding&gt;
          &lt;validate&gt;true&lt;/validate&gt;
          &lt;dbUrl&gt;jdbc:mysql://localhost:3306/hrtool?useUnicode=true&amp;characterEncoding=UTF-8&lt;/dbUrl&gt;
          &lt;dbDriver&gt;com.mysql.jdbc.Driver&lt;/dbDriver&gt;
          &lt;dbSchema&gt;database&lt;/dbSchema&gt;
          &lt;dbUser&gt;user&lt;/dbUser&gt;
          &lt;dbPassword&gt;password&lt;/dbPassword&gt;
        &lt;/configuration&gt;
        &lt;dependencies&gt;
        &lt;dependency&gt;
            &lt;groupId&gt;log4j&lt;/groupId&gt;
            &lt;artifactId&gt;log4j&lt;/artifactId&gt;
            &lt;version&gt;1.2.13&lt;/version&gt;
            &lt;scope&gt;runtime&lt;/scope&gt;
          &lt;/dependency&gt;
          &lt;dependency&gt;
            &lt;groupId&gt;org.apache.poi&lt;/groupId&gt;
            &lt;artifactId&gt;poi&lt;/artifactId&gt;
            &lt;version&gt;3.5-beta5&lt;/version&gt;
            &lt;scope&gt;runtime&lt;/scope&gt;
          &lt;/dependency&gt;
        &lt;/dependencies&gt;
      &lt;/plugin&gt;
    &lt;/plugins&gt;
  &lt;/build&gt;
&lt;/project&gt;

```

<p>В конфигурации необходимо указать как минимум следующие параметры:</p>
<ol><li><span style=" font-family:'Courier New,courier';">dbUrl</span> - строка подключения к базе данных в формате JDBC</li>
<li><span style=" font-family:'Courier New,courier';">dbDriver</span> - используемый драйвер базы данных</li>
<li><span style=" font-family:'Courier New,courier';">dbSchema</span> - имя схемы базы данных</li>
<li><span style=" font-family:'Courier New,courier';">dbUser</span> - имя пользователя, под которым подключаемся к базе данных</li>
<li><span style=" font-family:'Courier New,courier';">dbPassword</span> - пароль пользователя для подключения к базе данных</li>
</ol>
<p>Кроме использования файла pom.xml databene поддерживает возможность указания параметров в файле benerator.properties, что может быть удобно.</p>
<p>Databene benerator обладает следующими возможностями:</p>
<ol><li>Решение проблемы создания данных в общем виде. На данный момент поддерживаются XML и реляционные базы данных, но не за горами поддержка веб-сервисов, SAP и любых других систем через механизм расширений.</li>
<li>Юзабилити. Databene-benerator позволяет упростить создание тестовых данных для сложной модели прикладной области.</li>
<li>Обработка больших объёмов данных.</li>
<li>Высокая производительность.</li>
<li>Поддержка доменных областей.</li>
<li>Качество данных. Фреймворк поддерживает проверку ограничений модели прикладной области.</li>
<li>Компонентная, легкорасширяемая архитектура.</li>
<li>Широкие возможности изменения и настройки генерации тестовых данных</li>
<li>Создание тестовых данных с нуля.</li>
<li>Импорт и анонимизация реальных данных.</li>
</ol>
<p>В комплекте идёт толковая, но, к сожалению, неполная <a href="http://databene.org/download/databene-benerator-manual-0.6.0.pdf">документация</a> по возможностям.</p>