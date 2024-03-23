-- 1. Отобразите все записи из таблицы company по компаниям, которые закрылись.

SELECT *
FROM company
WHERE status LIKE '%close%'


-- 2. Отобразите количество привлечённых средств для новостных компаний США. 
-- Используйте данные из таблицы company. 
-- Отсортируйте таблицу по убыванию значений в поле funding_total.

SELECT funding_total
FROM company
WHERE category_code = 'news' AND country_code = 'USA'
ORDER BY funding_total DESC


-- 3. Найдите общую сумму сделок по покупке одних компаний другими в долларах. 
-- Отберите сделки, которые осуществлялись только за наличные с 2011 по 2013 год включительно.

SELECT SUM(price_amount)
FROM acquisition
WHERE term_code = 'cash' AND EXTRACT(YEAR FROM acquired_at) IN (2011, 2012, 2013)


-- 4. Отобразите имя, фамилию и названия аккаунтов людей в поле network_username, у которых названия аккаунтов начинаются на 'Silver'.

SELECT first_name, last_name, twitter_username
FROM people
WHERE twitter_username LIKE 'Silver%'


-- 5. Выведите на экран всю информацию о людях, у которых названия аккаунтов в поле network_username содержат подстроку 'money', а фамилия начинается на 'K'.

SELECT *
FROM people
WHERE twitter_username LIKE '%money%' AND last_name LIKE 'K%'


-- 6. Для каждой страны отобразите общую сумму привлечённых инвестиций, которые получили компании, зарегистрированные в этой стране. 
-- Страну, в которой зарегистрирована компания, можно определить по коду страны. 
-- Отсортируйте данные по убыванию суммы.

SELECT country_code, SUM(funding_total) AS sum_funding_total
FROM company
GROUP BY country_code
ORDER BY sum_funding_total DESC


-- 7. Составьте таблицу, в которую войдёт дата проведения раунда, а также минимальное и максимальное значения суммы инвестиций, привлечённых в эту дату.
-- Оставьте в итоговой таблице только те записи, в которых минимальное значение суммы инвестиций не равно нулю и не равно максимальному значению.

SELECT funded_at, 
       MIN(raised_amount) AS min_raised_amount, 
       MAX(raised_amount) AS max_raised_amount
FROM funding_round
GROUP BY funded_at
HAVING MIN(raised_amount) <> 0 AND MIN(raised_amount) <> MAX(raised_amount)


-- 8. Создайте поле с категориями:
-- Для фондов, которые инвестируют в 100 и более компаний, назначьте категорию high_activity.
-- Для фондов, которые инвестируют в 20 и более компаний до 100, назначьте категорию middle_activity.
-- Если количество инвестируемых компаний фонда не достигает 20, назначьте категорию low_activity.
-- Отобразите все поля таблицы fund и новое поле с категориями.

SELECT *,
    CASE
        WHEN invested_companies >= 100 THEN 'high_activity'
        WHEN 20 <= invested_companies AND invested_companies < 100 THEN 'middle_activity'
        WHEN invested_companies < 20 THEN 'low_activity'
    END
FROM fund

-- 9. Для каждой из категорий, назначенных в предыдущем задании, 
-- посчитайте округлённое до ближайшего целого числа среднее количество инвестиционных раундов, в которых фонд принимал участие. 
-- Выведите на экран категории и среднее число инвестиционных раундов. 
-- Отсортируйте таблицу по возрастанию среднего.

SELECT 
       CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity,
       ROUND(AVG(investment_rounds)) AS avg_investment_rounds
FROM fund
GROUP BY activity
ORDER BY avg_investment_rounds ASC


-- 10. Проанализируйте, в каких странах находятся фонды, которые чаще всего инвестируют в стартапы. 
-- Для каждой страны посчитайте минимальное, максимальное и среднее число компаний, в которые инвестировали фонды этой страны, основанные с 2010 по 2012 год включительно. 
-- Исключите страны с фондами, у которых минимальное число компаний, получивших инвестиции, равно нулю. 
-- Выгрузите десять самых активных стран-инвесторов: отсортируйте таблицу по среднему количеству компаний от большего к меньшему. 
-- Затем добавьте сортировку по коду страны в лексикографическом порядке.

SELECT country_code, 
       MIN(invested_companies) AS min_invested_companies,
       MAX(invested_companies) AS max_invested_companies,
       AVG(invested_companies) AS avg_invested_companies
FROM fund
WHERE EXTRACT(YEAR FROM founded_at) in (2010, 2011, 2012)
GROUP BY country_code
HAVING MIN(invested_companies) <> 0
ORDER BY avg_invested_companies DESC, country_code ASC
LIMIT 10


-- 11. Отобразите имя и фамилию всех сотрудников стартапов. 
-- Добавьте поле с названием учебного заведения, которое окончил сотрудник, если эта информация известна.

SELECT p.first_name, p.last_name, e.instituition
FROM people AS p
LEFT JOIN education AS e ON p.id = e.person_id


-- 12. Для каждой компании найдите количество учебных заведений, которые окончили её сотрудники. 
-- Выведите название компании и число уникальных названий учебных заведений. 
-- Составьте топ-5 компаний по количеству университетов.

SELECT c.name, COUNT(DISTINCT e.instituition)
FROM company AS c
JOIN people AS p ON p.company_id = c.id
JOIN education AS e ON p.id = e.person_id
GROUP BY c.name
ORDER BY COUNT(DISTINCT e.instituition) DESC
LIMIT 5


-- 14. Составьте список уникальных номеров сотрудников, которые работают в компаниях, отобранных в предыдущем задании.

SELECT id
FROM people
WHERE company_id IN (SELECT c.id
                      FROM company AS c
                      JOIN funding_round AS fr ON fr.company_id = c.id
                      WHERE fr.is_first_round = 1 
                            AND fr.is_last_round = 1
                            AND c.status = 'closed'
                      GROUP BY c.id)
GROUP BY id


-- 15. Составьте таблицу, куда войдут уникальные пары с номерами сотрудников из предыдущей задачи и учебным заведением, которое окончил сотрудник.

SELECT person_id, instituition
FROM education
WHERE person_id IN (SELECT id
                    FROM people
                    WHERE company_id IN (SELECT c.id
                                         FROM company AS c
                                         JOIN funding_round AS fr ON fr.company_id = c.id
                                         WHERE fr.is_first_round = 1 
                                               AND fr.is_last_round = 1
                                               AND c.status = 'closed'
                                         GROUP BY c.id)
                     GROUP BY id)
GROUP BY person_id, instituition


-- 16. Посчитайте количество учебных заведений для каждого сотрудника из предыдущего задания. 
-- При подсчёте учитывайте, что некоторые сотрудники могли окончить одно и то же заведение дважды.

SELECT person_id, COUNT(instituition)
FROM education
WHERE person_id IN (SELECT id
                    FROM people
                    WHERE company_id IN (SELECT c.id
                                         FROM company AS c
                                         JOIN funding_round AS fr ON fr.company_id = c.id
                                         WHERE fr.is_first_round = 1 
                                               AND fr.is_last_round = 1
                                               AND c.status = 'closed'
                                         GROUP BY c.id)
                     GROUP BY id)
GROUP BY person_id --, instituition


-- 17. Дополните предыдущий запрос и выведите среднее число учебных заведений (всех, не только уникальных), 
-- которые окончили сотрудники разных компаний. 
-- Нужно вывести только одну запись, группировка здесь не понадобится.

SELECT AVG(cnt_instituition)
FROM (SELECT person_id, COUNT(instituition) AS cnt_instituition
      FROM education
      WHERE person_id IN (SELECT id
                          FROM people
                          WHERE company_id IN (SELECT c.id
                                               FROM company AS c
                                               JOIN funding_round AS fr ON fr.company_id = c.id
                                               WHERE fr.is_first_round = 1 
                                                     AND fr.is_last_round = 1
                                                     AND c.status = 'closed'
                                               GROUP BY c.id)
                           GROUP BY id)
      GROUP BY person_id) AS avg_universitets


-- 18. Напишите похожий запрос: выведите среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники Socialnet.

SELECT AVG(cnt_instituition)
FROM (
      SELECT person_id, COUNT(instituition) AS cnt_instituition
      FROM education
      WHERE person_id IN (SELECT id
                          FROM people
                          WHERE company_id IN (SELECT c.id
                                               FROM company AS c
                                               JOIN funding_round AS fr ON fr.company_id = c.id
                                               WHERE c.name = 'Facebook'
                                                     --fr.is_first_round = 1 
                                                     -- AND fr.is_last_round = 1
                                                     -- AND c.status = 'closed'
                                               GROUP BY c.id)
                           GROUP BY id)
      GROUP BY person_id) AS avg_universitets


-- 19. Составьте таблицу из полей:
-- name_of_fund — название фонда;
-- name_of_company — название компании;
-- amount — сумма инвестиций, которую привлекла компания в раунде.
-- В таблицу войдут данные о компаниях, в истории которых было больше шести важных этапов, а раунды финансирования проходили с 2012 по 2013 год включительно.

SELECT f.name AS name_of_fund,
       c.name AS name_of_company,
       fr.raised_amount AS amount
FROM investment AS i
LEFT JOIN fund AS f ON i.fund_id = f.id
LEFT JOIN funding_round AS fr ON fr.id = i.funding_round_id
INNER JOIN company AS c ON c.id = i.company_id
WHERE c.id IN (SELECT id
               FROM company
               WHERE milestones > 6)
      AND fr.id IN (SELECT id
                    FROM funding_round
                    WHERE EXTRACT(YEAR FROM CAST(funded_at AS date)) IN (2012, 2013))


-- 20. Выгрузите таблицу, в которой будут такие поля:
-- название компании-покупателя;
-- сумма сделки;
-- название компании, которую купили;
-- сумма инвестиций, вложенных в купленную компанию;
-- доля, которая отображает, во сколько раз сумма покупки превысила сумму вложенных в компанию инвестиций, округлённая до ближайшего целого числа.
-- Не учитывайте те сделки, в которых сумма покупки равна нулю. Если сумма инвестиций в компанию равна нулю, исключите такую компанию из таблицы. 
-- Отсортируйте таблицу по сумме сделки от большей к меньшей, а затем по названию купленной компании в лексикографическом порядке. 
-- Ограничьте таблицу первыми десятью записями.

WITH
-- Компании-покупатели
ag AS (
    SELECT a.acquiring_company_id, a.price_amount, c.name AS buyer, a.id
    FROM acquisition AS a
    LEFT JOIN company AS c ON a.acquiring_company_id = c.id
    WHERE a.price_amount <> 0
),

-- Компании, ктр были проданы
ad AS (
    SELECT a.acquired_company_id, c.funding_total, c.name AS sold, a.id
    FROM acquisition AS a
    LEFT JOIN company AS c ON a.acquired_company_id = c.id
    WHERE c.funding_total <> 0
)

SELECT ag.buyer, 
       ag.price_amount, 
       ad.sold, 
       ad.funding_total,
       ROUND(ag.price_amount / ad.funding_total) AS ratio
FROM ag INNER JOIN ad ON ag.id = ad.id
ORDER BY ag.price_amount DESC, ad.sold ASC
LIMIT 10


-- 21. Выгрузите таблицу, в которую войдут названия компаний из категории social, получившие финансирование с 2010 по 2013 год включительно. 
-- Проверьте, что сумма инвестиций не равна нулю. Выведите также номер месяца, в котором проходил раунд финансирования.

SELECT c.name AS company_name,
       EXTRACT(MONTH FROM CAST(funded_at AS date)) AS month_round
FROM company AS c
JOIN funding_round AS fr ON fr.company_id = c.id
WHERE c.category_code = 'social'
      AND EXTRACT(YEAR FROM CAST(funded_at AS date)) IN (2010, 2011, 2012, 2013)
      AND fr.raised_amount <> 0


-- 22. Отберите данные по месяцам с 2010 по 2013 год, когда проходили инвестиционные раунды. 
-- Сгруппируйте данные по номеру месяца и получите таблицу, в которой будут поля:
-- номер месяца, в котором проходили раунды;
-- количество уникальных названий фондов из США, которые инвестировали в этом месяце;
-- количество компаний, купленных за этот месяц;
-- общая сумма сделок по покупкам в этом месяце.

WITH
-- ID funds from USA
funds_usa AS (
              SELECT EXTRACT(MONTH FROM CAST(fr.funded_at AS date)) AS month_funded_at,
                     COUNT(DISTINCT f.name) as cnt_names
              FROM fund AS f
              LEFT JOIN investment AS i ON f.id = i.fund_id
              LEFT JOIN funding_round AS fr ON i.funding_round_id = fr.id
              WHERE f.country_code = 'USA'
                    AND EXTRACT(YEAR FROM CAST(fr.funded_at AS date)) BETWEEN 2010 AND 2013
              GROUP BY month_funded_at),

acquisition AS (SELECT EXTRACT(MONTH FROM CAST(a.acquired_at AS date)) AS acquisition_month,
                       COUNT(a.acquired_company_id) AS cnt_acquired_company,
                       SUM(price_amount) AS total_amount
                FROM acquisition AS a
                WHERE EXTRACT(YEAR FROM CAST(a.acquired_at AS date)) BETWEEN 2010 AND 2013
                GROUP BY acquisition_month
               )

SELECT funds_usa.month_funded_at,
       funds_usa.cnt_names,
       acquisition.cnt_acquired_company,
       acquisition.total_amount
FROM funds_usa
LEFT JOIN acquisition ON acquisition.acquisition_month = funds_usa.month_funded_at


-- 23. Составьте сводную таблицу и выведите среднюю сумму инвестиций для стран, в которых есть стартапы, зарегистрированные в 2011, 2012 и 2013 годах. 
-- Данные за каждый год должны быть в отдельном поле. 
-- Отсортируйте таблицу по среднему значению инвестиций за 2011 год от большего к меньшему.

WITH
     inv_2011 AS (SELECT country_code,
                         AVG(funding_total) AS avg_funding_total_2011
                  FROM company
                  WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) = 2011
                  GROUP BY country_code
                 ),
     inv_2012 AS (SELECT country_code,
                         AVG(funding_total) AS avg_funding_total_2012
                  FROM company
                  WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) = 2012
                  GROUP BY country_code
                 ),
     inv_2013 AS (SELECT country_code,
                         AVG(funding_total) AS avg_funding_total_2013
                  FROM company
                  WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) = 2013
                  GROUP BY country_code
                 )
SELECT inv_2011.country_code, 
       inv_2011.avg_funding_total_2011,
       inv_2012.avg_funding_total_2012,
       inv_2013.avg_funding_total_2013
FROM inv_2011
INNER JOIN inv_2012 ON inv_2011.country_code = inv_2012.country_code
INNER JOIN inv_2013 ON inv_2012.country_code = inv_2013.country_code
ORDER BY inv_2011.avg_funding_total_2011 DESC
