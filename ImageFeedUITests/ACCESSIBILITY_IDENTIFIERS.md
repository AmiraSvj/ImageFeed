# Accessibility Identifiers для UI-тестов

Для корректной работы UI-тестов необходимо добавить следующие Accessibility Identifiers в UI элементы:

## AuthViewController
- **Кнопка авторизации**: `"Authenticate"`

## WebViewViewController  
- **WebView**: `"UnsplashWebView"`

## ImagesListViewController
- **Кнопка лайка (выключена)**: `"like button off"`
- **Кнопка лайка (включена)**: `"like button on"`

## SingleImageViewController
- **Кнопка "Назад"**: `"nav back button white"`

## ProfileViewController
- **Кнопка логаута**: `"logout button"`
- **Имя пользователя**: `"Name Lastname"`
- **Username**: `"@username"`

## Alerts
- **Заголовок алерта логаута**: `"Bye bye!"`
- **Кнопка "Да" в алерте**: `"Yes"`

## TabBar
- **Таб "Лента"**: индекс 0
- **Таб "Профиль"**: индекс 1

## Как добавить Accessibility Identifier:

### В Storyboard:
1. Выберите элемент в Interface Builder
2. В Attributes Inspector найдите "Accessibility"
3. В поле "Identifier" введите нужное значение

### В коде:
```swift
button.accessibilityIdentifier = "Authenticate"
webView.accessibilityIdentifier = "UnsplashWebView"
```

## Важные замечания:

1. **Безопасность**: Не добавляйте реальные логин и пароль в код тестов
2. **Стабильность**: Используйте уникальные и описательные идентификаторы
3. **Консистентность**: Одинаковые элементы должны иметь одинаковые идентификаторы
4. **Тестирование**: Проверьте, что все идентификаторы работают в тестах
