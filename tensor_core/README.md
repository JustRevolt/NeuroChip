# Тензорное ядро

Прототип тензорного ядра для ускорения расчета сверточных нейронных сетей

----

Содержание:

1. [Описание](#Tensor-core-Description)
    1. [Архитектура](#Tensor-core-architecture)
    2. [Микроархитектура вычислительной подсистемы](#Tensor-core-computing-unit-microarchitecture)
2. [Структура директории тензорного ядра](#Tensor-core-dir-structure)
3. [Иструкция по моделированию](#Tensor-core-Simulation-instruction)

## Описание <a name="Tensor-core-Description"></a>

### Архитектура. <a name="Tensor-core-architecture"></a>

<img alt="tensor core architecture with fully separated bus" src="doc/imgs/architecture-fully_separated_bus_Mem-CU.png" width="800"/>

### Микроархитектура вычислительной подсистемы: <a name="Tensor-core-computing-unit-microarchitecture"></a>

- __Микроархитектура систолического массива__

    <img alt="Systolic array microarchitecture" src="doc/imgs/microarchitecture-Systolic_Array.png" width="600"/>

- __Микроархитектура MAC блоков__

    <img alt="MAC microarchitecture" src="doc/imgs/microarchitecture-MAC.png" width="400"/>

- __Микроархитектура блока аккумулирования__

    <img alt="Accumulators microarchitecture" src="doc/imgs/microarchitecture-Accumulators.png" width="700"/>

- __Микроархитектура блока смещений__

    <img alt="Offsets microarchitecture" src="doc/imgs/microarchitecture-Offsets.png" width="500"/>

- __Микроархитектура блока активаций__

    <img alt="Activation microarchitecture" src="doc/imgs/microarchitecture-Activation.png" width="400"/>

- __Микроархитектура блока пуллинга__

    <img alt="Polling microarchitecture" src="doc/imgs/microarchitecture-Polling.png" width="400"/>


## Структура директории тензорного ядра <a name="Tensor-core-dir-structure"></a>

`doc` - файлы с документации для используемых библиотек и полезной информацией

`src` - исходные файлы модулей тензорного ядра

`tb` - файлы тестового окружения для тестирования модулей тензорного ядра в среде моделирования

`xc7a100tcsg324_project` - Проект Xilinx Vivado для ПЛИС xc7a100tcsg324

`xc7a100tcsg324_project/waveform_cfg` - Файлы конфигурации временных диаграмм Xilinx Vivado

## Иструкция по моделированию <a name="Tensor-core-Simulation-instruction"></a>

Требуется версия Xilinx Vivado CAD: v2019.1 (64-разрядная версия)

1. Загрузите и установите Xilinx Vivado CAD.
2. Откройте проект Vivado `/xc7a100tcsg324_project/xc7a100tcsg324_project.xpr`
3. Выберите необходимый файл testbench и установите как основной ("Set as top").
4. Запустите поведенческое моделирование ("Behavioral Simulation")
5. Результаты тестирования отобразятся в консоли TCL