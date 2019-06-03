# Установка и настройка пакета ROS Kinetic

Для работы с такими инструментами как: rqt, rviz и т. д., а также для запуска симулятора (SITL) вам потребуется установленный и настроенный пакет ROS.

> **Hint** Более подробную инструкцию по установке смотрите в [основной статье](http://wiki.ros.org/kinetic/Installation/Ubuntu).

<!-- -->

> **Hint** В случае, если вы используете Ubuntu версии 18.04, вместо ROS Kinetic вам нужно будет установить ROS Melodic. Полную инструкцию по установке вы можете найти [здесь](http://wiki.ros.org/melodic/Installation/Ubuntu).

## Установка ROS Kinetic на Ubuntu

Для того, чтобы загрузить и установить правильную версию пакета требуется сделать настройки репозиториев, для этого откройте "Программы и обновления" и разрешите `restricted`, `universe` и `multiverse`.

Настройте свою систему, для того что бы вы могли принимать программное обеспечение с `packages.ros.org`, выполнив команду:

```bash
sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
```

Настройте ключи доступа в своей системе для правильной загрузки:

```bash
sudo apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116
```

Убедитесь в том, что вы имеете последние версии индексов пакетов:

```bash
sudo apt-get update
```

Теперь установите сам пакет ROS.

+ Если вы планируете использовать ROS вместе с симуляцией (также содержит инструменты: rqt, rviz и т. д):

    ```bash
    sudo apt-get install ros-kinetic-desktop-full
    ```

+ Если вы планируете использовать ROS исключительно работать с инструментами rqt, rviz и т. д:

    ```bash
    sudo apt-get install ros-kinetic-desktop
    ```

После установки пакета вам нужно инициализировать `rosdep`.
Пакет `rosdep` позволит вам легко устанавливать системные зависимости для источника, который вы хотите скомпилировать, а также необходим для запуска некоторых основных компонентов в ROS:

```bash
sudo rosdep init
rosdep update
```

Если вам не удобно запускать переменное окружение вручную каждый раз, вы можете настроить его так, чтобы оно добавлялось в ваш сеанс bash при каждом запуске новой оболочки:

```bash
echo "source /opt/ros/kinetic/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

Если вы хотите установить какие-либо дополнительные пакеты для вашего ROS Kinetic просто используйте:

```bash
sudo apt-get install ros-kinetic-PACKAGE
```

## Обновление пакетов на Клевере

Подключите Raspberry Pi с образом Клевера к сети и выполните:

```bash
sudo apt update
sudo apt upgrade
```
