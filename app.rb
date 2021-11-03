#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'# чтобы не перезапускать приложение
require 'sqlite3'

def init_db
	@db = SQLite3::Database.new 'leprosorium.db'
	@db.results_as_hash = true
end

# before вызывается каждый раз при перезагрузке
# любой страницы

before do
	# инициализация базы данных
	init_db
end

# configure  вызывается каждый раз при конфигурации приложения
# когда изменился код и перезагрузилась страница
configure do 
	# инициализация базы данных
	init_db
	# создает таблицу если не существет
	@db.execute 'CREATE TABLE IF NOT EXISTS Posts 
	(
		id INTEGER PRIMARY KEY AUTOINCREMENT, 
		created_date DATE, 
		content TEXT
	)'
	
	# создает таблицу если не существет
	@db.execute 'CREATE TABLE IF NOT EXISTS Comments
	(
		id INTEGER PRIMARY KEY AUTOINCREMENT, 
		created_date DATE, 
		content TEXT,
		post_id integer
	)'
end

get '/' do
	#выбираем список постов из базы данных

	@results = @db.execute 'select * from Posts order by id desc'

	erb :index	
end

# обработчик get-запроса /new
#(браузер получает страницу с сервера)
get '/new' do
	erb :new
end

# обраблтчик post-запроса /new
# (браузер отправляет данные на сервер)
post '/new' do
	# получаем переменную из пост-запроса
	content = params[:content]

	if content.length <= 0
			@error = 'Type post text'
			return erb :new
	end	
	
	#сохранение данных в базе данных
	@db.execute 'insert into Posts (content, created_date) values (?, datetime())', [content]

	# перенаправляем на главную страницу
	redirect to '/'
  end

# вывод инф о посто

get '/details/:id'do
  	# получаем переменную из url
  	post_id = params[:id]

	# получаем список постов
	# (у нас будет только один пост)
  	results = @db.execute 'select * from Posts where id = ?', [post_id]
  	
	# выбираем этот один пост в переменную @row  
	@row = results[0]

	#выбираем комментарии для нашего поста
	@comments = db.execute 'select * from Comments where post_id = ? order by id' , [post_id]

	# возвращаем представление details.erb
  	erb :details
end

# обработчик post-запроса /details/...
#(браузер отправляет данные на сервер, мы их принииаем)

post '/details/:id'do
	# получаем переменную из url
	post_id = params[:id]

	# получаем переменную из пост-запроса
	content = params[:content]	

	#сохранение данных в базе данных
	@db.execute 'insert into Comments
		(
			content, 
			created_date,
			post_id
		)
			 values 
			(
				?,
				datetime(),
				?
			)', [content, post_id]
	# перенаправляем на страницу  поста
	redirect to '/details/' + post_id
end