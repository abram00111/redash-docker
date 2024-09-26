1) Копируем _**.env.example**_ в файл _**.env**_

2) Заполняем данные для БД
    ```
    POSTGRES_PASSWORD=пароль для БД redash
    POSTGRES_USER=пользователь для БД redash
    POSTGRES_DB=БД для redash
    ```

3) Генерируем пароль для дефолтного пользователя в clickhouse
    ```
    make generate-password password="yourPassword"
    ```
   и указываем его для default пользователя в ./docker/clickhouse/users.xml в password_sha256_hex
   ```
    <?xml version="1.0"?>
    <yandex>
        ...
        <users>
            ...
            <default>
                ...
                <password_sha256_hex>Записываем хэш функцию от пароля сюда</password_sha256_hex>
            </default>
        </users>
   </yandex>
   ```

4) Запускаем контейнеры
    ```
    make up
    ```
   
5) После успешного запуска контейнеров можно открыть вэб интерфейс redash http://localhost:5000, но для оперирования 
   данными еще необходимо настроить Clickhouse, либо использовать другую БД.

6) Заходим в контейнер Clickhouse
   ```
   make clickhouse
   ```
   и авторизуемся под default пользователем 
   ```
   clickhouse-client --password=Ваш пароль созданный на шаге 3 (не хэш)
   ```
   
7) Создаем пользователя которого отдадим для redash
   ```
   CREATE USER username IDENTIFIED WITH sha256_password BY 'password' 
   ```
   
   username и password нам понадобятся позже
8) Создаем БД откуда redash будет получать данные dbName имя БД понадобится позже
   ```
   CREATE DATABASE IF NOT EXISTS dbName
   ```
   
9) Даем права пользователю к БД. username из пункта 7, dbName из пункта 8
   ```
   GRANT SELECT(*) ON dbName.* TO username
   ```
   более подробно о правах можно прочитать тут https://clickhouse.com/docs/ru/sql-reference/statements/grant

10) Редактируем конфиг clickhouse, чтоб ограничить default пользователя правами в файле ./docker/clickhouse/users.xml 
    удаляем или комментируем строчку access_management
   ```
    <?xml version="1.0"?>
    <yandex>
        ...
        <users>
            ...
            <default>
                ...
                <!--<access_management>1</access_management>-->
            </default>
        </users>
   </yandex>
   ```

11) Теперь в redash можно создать подключение к clickhouse в DataSources
```
url - http://clickhouse:8123
User - из пункта 7
Password - из пункта 7
Database Name - из пункта 8
```