services:
  # Основное приложение
  app:
    build: .
    depends_on:
      init-setup:
        condition: service_completed_successfully

  # Одноразовый сервис (профиль "init")
  init-setup:
    build: .
    profiles: ["init"] # Запускается только явно или через зависимости
    command: ["sh", "-c", "echo 'Doing one-time task...' && rm -rf /tmp/*"]
    # Гарантируем, что контейнер не будет перезапускаться после выполнения
    restart: "no" 
    
    Если нужно «Один раз за всю историю проекта»
    command: >
      sh -c "if [ ! -f /data/.initialized ]; then
               echo 'Первый запуск...';
               touch /data/.initialized;
             else
               echo 'Уже выполнялось, пропускаю.';
             fi"
         
    #-------------
    Как это работает:
    1. Профиль (profiles): 
        Сервис init-setup не запустится, если вы просто напишете docker-compose up. Он «спящий».
    2. Зависимость (depends_on): 
        Когда вы запускаете основное приложение (docker-compose up app), Compose видит зависимость.
    3. Условие (service_completed_successfully): 
        app не начнет загрузку, пока init-setup не завершит работу с кодом выхода 0.
        
    Как запустить:
        Автоматически с приложением:
        bash
            docker compose --profile init up   
             
        Только инициализацию (вручную один раз):
        bash
            docker compose run --rm init-setup    
