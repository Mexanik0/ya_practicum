-- 1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки».
SELECT COUNT(id)
FROM stackOVERflow.posts
WHERE favorites_count >= 100 or score > 300 AND post_type_id = 1


-- 3. Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.
SELECT COUNT(distinct b.user_id) AS usr_cnt
FROM stackOVERflow.badges AS b
inner JOIN stackOVERflow.users AS u on u.id = b.user_id
WHERE CAST(DATE_trunc('day', b.creation_DATE) AS DATE) = CAST(DATE_trunc('day', u.creation_DATE) AS DATE)


-- 4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?
SELECT COUNT(DISTINCT p.id) AS unique_posts_count
FROM stackOVERflow.posts p
JOIN stackOVERflow.users u ON p.user_id = u.id
JOIN stackOVERflow.votes v ON p.id = v.post_id
WHERE u.display_name = 'Joel Coehoorn'
AND v.vote_type_id != 0


-- 5. Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. 
-- Таблица должна быть отсортирована по полю id.
SELECT *,
       RANK() OVER (ORDER BY id DESC) AS rank
FROM stackOVERflow.vote_types
ORDER BY id


-- 6. Отберите 10 пользователей, которые поставили больше всего голосов типа Close. 
-- Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. 
-- Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.
SELECT user_id,
       COUNT(id) AS cnt_votes
FROM stackOVERflow.votes
WHERE vote_type_id = 6
GROUP BY user_id
ORDER BY cnt_votes DESC, user_id DESC
LIMIT 10


-- 7. Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
-- Отобразите несколько полей:
-- идентификатор пользователя;
-- число значков;
-- место в рейтинге — чем больше значков, тем выше рейтинг.
-- Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
-- Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.
SELECT user_id,
       COUNT(distinct id) AS cnt_badges,
       dense_rank() OVER(ORDER BY COUNT(distinct id) DESC)
FROM stackOVERflow.badges
WHERE CAST(DATE_trunc('day', creation_DATE) AS DATE) >= '2008-11-15'
      AND CAST(DATE_trunc('day', creation_DATE) AS DATE) <= '2008-12-15'
GROUP BY user_id
ORDER BY cnt_badges DESC, user_id
LIMIT 10


-- 8. Сколько в среднем очков получает пост каждого пользователя?
-- Сформируйте таблицу из следующих полей:
-- заголовок поста;
-- идентификатор пользователя;
-- число очков поста;
-- среднее число очков пользователя за пост, округлённое до целого числа.
-- Не учитывайте посты без заголовка, а также те, что набрали ноль очков.
SELECT title, 
       user_id,
       score,
       round(avg(score) OVER(partition BY user_id), 0) AS avg_score 
FROM stackOVERflow.posts
WHERE title IS NOT NULL AND score !=0


-- 9. Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. 
-- Посты без заголовков не должны попасть в список.
SELECT p.title
FROM stackOVERflow.posts AS p
JOIN (SELECT user_id,
             COUNT(id) AS cnt_badges
      FROM stackOVERflow.badges
      GROUP BY user_id) AS b on b.user_id = p.user_id
WHERE p.title !='' AND b.cnt_badges >= 1000


-- 10. Напишите запрос, который выгрузит данные о пользователях из Канады (англ. Canada). 
-- Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
-- пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
-- пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
-- пользователям с числом просмотров меньше 100 — группу 3.
-- Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. 
-- Пользователи с количеством просмотров меньше либо равным нулю не должны войти в итоговую таблицу.
SELECT id, 
       views, 
       CASE
           WHEN views >= 350 THEN 1
           WHEN views >= 100 AND views < 350 THEN 2
           WHEN views < 100 THEN 3
       END
FROM stackOVERflow.users
WHERE location like '%Canada%' AND views > 0 


-- 11. Дополните предыдущий запрос. 
-- Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. 
-- Выведите поля с идентификатором пользователя, группой и количеством просмотров. 
-- Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.
WITH
us_users AS (SELECT id, 
           views, 
           CASE
               WHEN views >= 350 THEN 1
               WHEN views >= 100 AND views < 350 THEN 2
               WHEN views < 100 THEN 3
           END AS GROUPs
    FROM stackOVERflow.users
    WHERE location like '%Canada%' AND views > 0)
    
SELECT id,
       GROUPs,
       views
FROM (   
          SELECT id,
                 views,
                 GROUPs,
                 MAX(views) OVER (PARTITION BY GROUPs ORDER BY views DESC) AS max_views
            FROM us_users
         ) AS max_us
WHERE views =  max_views
ORDER BY views DESC, id; 


-- 12. Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
-- номер дня;
-- число пользователей, зарегистрированных в этот день;
-- сумму пользователей с накоплением.
WITH 
us_users AS (SELECT CAST(DATE_trunc('day', creation_DATE) AS DATE) AS dt_day,
                   COUNT(id) AS cnt_users
            FROM stackOVERflow.users
            WHERE CAST(DATE_trunc('month', creation_DATE) AS DATE) = '2008-11-01'
            GROUP BY dt_day)
            
SELECT extract(DAY FROM CAST(dt_day AS DATE)), cnt_users,
       sum(cnt_users) OVER(ORDER BY dt_day)
FROM us_users


-- 13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. Отобразите:
-- идентификатор пользователя;
-- разницу во времени между регистрацией и первым постом.
WITH
us_users AS (SELECT p.user_id AS user_id, 
                    u.creation_DATE AS reg_DATE, 
                    min(p.creation_DATE) OVER(partition BY u.id) AS dt_first_post
             FROM stackOVERflow.posts AS p
             JOIN stackOVERflow.users AS u on p.user_id = u.id)
             
SELECT distinct user_id,
       dt_first_post - reg_DATE AS dt_diff
FROM us_users


-- 14. Выведите общую сумму просмотров у постов, опубликованных в каждый месяц 2008 года. 
-- Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. 
-- Результат отсортируйте по убыванию общего количества просмотров.
SELECT CAST(DATE_trunc('month', creation_DATE) AS DATE) AS dt_month,
       sum(views_count) AS sum_views
FROM stackOVERflow.posts
WHERE extract(year FROM CAST(creation_DATE AS DATE)) = 2008
GROUP BY dt_month
ORDER BY sum_views DESC


-- 15. Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. 
-- Вопросы, которые задавали пользователи, не учитывайте. 
-- Для каждого имени пользователя выведите количество уникальных значений user_id. 
-- Отсортируйте результат по полю с именами в лексикографическом порядке.
WITH
first_tab AS (SELECT u.display_name, COUNT(distinct p.user_id)   
              FROM stackOVERflow.posts AS p
              JOIN stackOVERflow.users AS u on u.id = p.user_id
              WHERE p.post_type_id = 2 AND
                    p.creation_DATE::DATE BETWEEN u.creation_DATE::DATE AND (u.creation_DATE::DATE + INTERVAL '1 month')
              GROUP BY u.display_name
              having COUNT(p.id) > 100)

SELECT *
FROM first_tab


-- 16. Выведите количество постов за 2008 год по месяцам. 
-- Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. 
-- Отсортируйте таблицу по значению месяца по убыванию.
SELECT CAST(DATE_trunc('month', creation_DATE) AS DATE) AS dt_month,
       COUNT(id) AS cnt_posts
FROM stackOVERflow.posts
WHERE extract(year FROM CAST(creation_DATE AS DATE)) = 2008
        AND user_id in (SELECT distinct u.id
                          FROM stackOVERflow.posts AS p
                          JOIN stackOVERflow.users AS u on u.id = p.user_id
                          WHERE CAST(DATE_trunc('month', u.creation_DATE) AS DATE) = '2008-09-01'
                                AND CAST(DATE_trunc('month', p.creation_DATE) AS DATE) = '2008-12-01')
GROUP BY dt_month
ORDER BY dt_month DESC


-- 17. Используя данные о постах, выведите несколько полей:
-- идентификатор пользователя, который написал пост;
-- дата создания поста;
-- количество просмотров у текущего поста;
-- сумма просмотров постов автора с накоплением.
-- Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста.
SELECT user_id,
       creation_DATE,
       views_count,
       sum(views_count) OVER(partition BY user_id ORDER BY creation_DATE) AS views_cum
FROM stackOVERflow.posts
ORDER BY user_id


-- 18. Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? 
-- Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. 
-- Нужно получить одно целое число — не забудьте округлить результат.
WITH
usr AS (SELECT user_id,
               COUNT(distinct extract(DAY FROM CAST(creation_DATE AS DATE))) AS dt_day
        FROM stackOVERflow.posts
        WHERE CAST(DATE_trunc('day', creation_DATE) AS DATE) >= '2008-12-01' AND 
              CAST(DATE_trunc('day', creation_DATE) AS DATE) <= '2008-12-07'
        GROUP BY user_id)
              
SELECT ROUND(AVG(dt_day))::INT AS result
FROM usr


-- 19. На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? Отобразите таблицу со следующими полями:
-- Номер месяца.
-- Количество постов за месяц.
-- Процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
-- Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. 
-- Округлите значение процента до двух знаков после запятой.
-- Напомним, что при делении одного целого числа на другое в PostgreSQL в результате получится целое число, округлённое до ближайшего целого вниз. 
-- Чтобы этого избежать, переведите делимое в тип numeric.
WITH
dt_m AS (SELECT EXTRACT(MONTH FROM CAST(creation_DATE AS DATE)) AS dt_month,
       COUNT(id) AS posts_amt
FROM stackOVERflow.posts
WHERE CAST(DATE_TRUNC('month', creation_DATE) AS DATE) >= '2008-09-01' AND
      CAST(DATE_TRUNC('month', creation_DATE) AS DATE) < '2009-01-01'
GROUP BY dt_month)

SELECT *,
       ROUND((posts_amt::NUMERIC / LAG(posts_amt) OVER() - 1) * 100, 2) AS post_amt_ratio
FROM dt_m


-- 20. Найдите пользователя, который опубликовал больше всего постов за всё время с момента регистрации. 
-- Выведите данные его активности за октябрь 2008 года в таком виде:
-- номер недели;
-- дата и время последнего поста, опубликованного на этой неделе.
WITH
top_user AS (SELECT user_id, COUNT(id) AS cnt_posts
             FROM stackOVERflow.posts
             --WHERE CAST(DATE_trunc('month', creation_DATE) AS DATE) = '2008-10-01'
             GROUP BY user_id
             ORDER BY cnt_posts DESC
             LIMIT 1)
             
SELECT extract(week FROM CAST(creation_DATE AS DATE)) AS num_week,
       max(creation_DATE) AS dt_lASt_post
FROM stackOVERflow.posts AS p
JOIN top_user AS u on u.user_id = p.user_id
WHERE p.user_id in (p.user_id) AND
      CAST(DATE_trunc('month', creation_DATE) AS DATE) = '2008-10-01'
GROUP BY num_week