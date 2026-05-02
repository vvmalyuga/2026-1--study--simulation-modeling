# Changelog

## [1.1.0] - 2026-02-26 

### Added
- Lab01: Exponential growth model
  - Basic ODE implementation
  - Parameter study with multiple growth rate values
  - Literate programming style with documentation
  - Jupyter notebooks and Quarto documents
 
## [1.2.0] - 2026-03-07

### Added
- Lab02: SIR and Lotka-Volterra models
  - SIR epidemiological model with ODE solution
  - Lotka-Volterra predator-prey model with ODE solution
  - Parametric studies for both models
  - Comprehensive plots and analysis
  - Jupyter notebooks for interactive exploration
  - Quarto documentation with mathematical derivations
  - Presentation and report in Denote naming format

### Changed
- Updated project structure for lab02
- Improved documentation with more detailed comments

### Fixed
- Nested git repository issues in project folders
- Submodule configuration for templates

## [v1.3.0] - 2026-03-21

### Added
- Лабораторная работа №3: агентное моделирование Daisyworld
- Реализация модели на Julia с пакетом Agents.jl
- Литературные скрипты и производные форматы (чистый код, Jupyter Notebook, Quarto)
- Отчёт и презентация в формате Quarto
- Параметрическое исследование модели
- Видео анимации (simulation.mp4, simulation.webm)
- Все файлы выложены на GitHub и GitVerse

### Changed
- Обновлена структура репозитория в соответствии с Denote

### Fixed
- Исправлены ошибки в путях и настройках Quarto для корректной сборки

## [1.4.0] - 2026-04-05

### Added
- Лабораторная работа №4: агентная модель SIR
  - Реализация на Julia с пакетом Agents.jl (файлы `sir_model.jl`, `sir_model_with_quarantine.jl`)
  - Базовый эксперимент, параметрическое сканирование коэффициента передачи, исследование миграции
  - Многокритериальная оптимизация параметров (BlackBoxOptim)
  - Литературные скрипты и производные форматы (чистый код, Jupyter Notebook, Quarto)
  - Дополнительные задания:
    - Карантинные меры (закрытие города при пороге заболеваемости)
    - Гетерогенность популяции (разные коэффициенты передачи для городов)
    - Пороговый анализ (нахождение минимального коэффициента передачи для эпидемии)
    - Оптимизация интенсивности миграции
  - Отчёт и презентация в формате Quarto
  - Все файлы выложены на GitHub и GitVerse

### Changed
- Обновлена структура репозитория для lab04 в соответствии с Denote
- Улучшена документация и комментарии к коду

### Fixed
- Исправлены пути к модулям и данные для корректной работы скриптов
- Устранены ошибки в параметрических сканированиях

## [1.5.0] - 2026-04-18

### Added
- Лабораторная работа №5: Аппарат сетей Петри. Задача «Обедающие философы»
  - Реализация модуля `DiningPhilosophers.jl` с определением структуры PetriNet
  - Построение классической сети Петри для пяти философов (приводит к deadlock)
  - Модифицированная сеть с арбитром, предотвращающая deadlock
  - Стохастическое моделирование с использованием алгоритма Гиллеспи
  - Детерминированное моделирование на основе ОДУ
  - Визуализация эволюции маркировок (графики `classic_simulation.png`, `arbiter_simulation.png`)
  - Сравнительный анализ состояния «Ест» (`final_report.png`)
  - Анимация работы классической сети (`philosophers_simulation.gif`)
  - Литературное программирование с `Literate.jl` и генерация чистого кода, Jupyter Notebook, Quarto-документов
  - Отчёт в форматах PDF, HTML, DOCX с перекрёстными ссылками и библиографией
  - Презентация в форматах revealjs и beamer

### Changed
- Обновлена структура репозитория для lab05 в соответствии с соглашением Denote
- Улучшена обработка графиков в Quarto для корректного отображения во всех форматах

### Fixed
- Исправлены конфликты окружений Julia в проекте
- Устранены ошибки вставки GIF в PDF с помощью условного отображения

## [1.6.0] - 2026-05-03

### Added
- Лабораторная работа №6: Реализация модели SIR в подходе сетей Петри
  - Модуль `SIRPetri.jl` с функциями построения сети, детерминированной и стохастической симуляции, визуализации
  - Базовый прогон с параметрами по умолчанию (β=0.3, γ=0.1) и сохранение результатов в CSV
  - Параметрическое сканирование коэффициента заражения β (0.1–0.8) и анализ пика заболеваемости и конечного числа выздоровевших
  - Анимация детерминированной динамики (`sir_animation.gif`) с покадровой визуализацией состояний S, I, R
  - Сравнительные графики детерминированной и стохастической траекторий инфицированных, чувствительности пика I к β
  - Литературное программирование: все скрипты переписаны в стиле Literate.jl, сгенерированы чистый код, Quarto-документы и Jupyter-ноутбуки
  - Отчёт в форматах PDF, HTML, DOCX с внедрёнными Quarto-файлами и перекрёстными ссылками
  - Презентация (revealjs + beamer) с отдельными слайдами для каждого графика и анимации
  - Все файлы выложены на GitHub и GitVerse, оформлен релиз v1.6.0
