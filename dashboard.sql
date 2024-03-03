--Уникальное кол-во посетителей сайта (разбивка по дням):
/*
select
distinct(count(s.visitor_id)) as visitors_count,
to_char(s.visit_date, 'yyyy-mm-dd') as date
from sessions s
group by date
order by date;
*/

--Каналы, которые приводят на сайт посетителей (разбивка по дням и каналам):
/*
select
distinct(count(s.visitor_id)) as visitors_count,
s.source,
s.medium,
s.campaign,
to_char(s.visit_date, 'yyyy-mm-dd') as date
from sessions s
group by
date,
s.source,
s.medium,
s.campaign
order by date;
*/

--Каналы, которые приводят на сайт посетителей (разбивка по неделям и каналам):
/*
select
distinct(count(s.visitor_id)) as visitors_count,
s.source,
s.medium,
s.campaign,
extract(week from s.visit_date) as week
from sessions s
group by
week,
s.source,
s.medium,
s.campaign
order by week;
*/

--Каналы, которые приводят на сайт посетителей (разбивка по месяцу и каналам):
/*
select
distinct(count(s.visitor_id)) as visitors_count,
s.source,
s.medium,
s.campaign,
to_char(s.visit_date, 'yyyy-mm') as month
from sessions s
group by
month,
s.source,
s.medium,
s.campaign
order by month;
*/

--Количество лидов (разбивка по дате):
/*
select
to_char(l.created_at, 'yyyy-mm-dd') as date,
count(l.lead_id) as lead_count
from leads l
group by date
order by date;
*/

--Конверсия из клика в лид:
/*
with tab as (
select
to_char(s.visit_date, 'yyyy-mm-dd') as v_date,
count(s.visitor_id) as click_count
from sessions s
group by 1
order by 1
), tab2 as (
select
to_char(l.created_at, 'yyyy-mm-dd') as l_date,
count(l.lead_id) as lead_count
from leads l
group by 1
order by 1
)
select
tab2.l_date as date,
round(((tab2.lead_count * 100.00) / tab.click_count), 2) as conversion
from tab2
join tab
on tab2.l_date = tab.v_date;
*/

--Конверсия из лида в оплату:
/*
with tab as (
select count(l.lead_id) as total_leads
from leads l
), tab1 as (
select count(l.lead_id) as paid_lead
from leads l
where amount != 0 or l.status_id = 142
)
select
round(((tab1.paid_lead * 100.00) / tab.total_leads), 2) as conversion
from tab1
cross join tab;
*/

--Считаем затраты на каждый канал (с разивкой по дням):
/*
select
to_char(va.campaign_date, 'yyyy-mm-dd'),
va.utm_source,
va.utm_medium,
va.utm_campaign,
sum(va.daily_spent) as daily_spent
from vk_ads va
group by 1, 2, 3, 4
union
select
to_char(ya.campaign_date, 'yyyy-mm-dd'),
ya.utm_source,
ya.utm_medium,
ya.utm_campaign,
sum(ya.daily_spent) as daily_spent
from ya_ads ya
group by 1, 2, 3, 4
order by 1, 2, 3, 4;
*/

--Выявляем окупаемость затрат на каналы (разбивка по дням по метрике roi):
/*
with tab as (
select
to_char(l.created_at, 'yyyy-mm-dd') as date,
s.source,
s.medium,
s.campaign,
sum(l.amount) as income
from leads l
left join sessions s
on s.visitor_id = l.visitor_id
group by 1, 2, 3, 4
order by 1, 2, 3, 4
), tab1 as (
select
to_char(va.campaign_date, 'yyyy-mm-dd') as date1,
va.utm_source,
va.utm_medium,
va.utm_campaign,
sum(va.daily_spent) as daily_spent
from vk_ads va
group by 1, 2, 3, 4
union
select
to_char(ya.campaign_date, 'yyyy-mm-dd'),
ya.utm_source as source,
ya.utm_medium,
ya.utm_campaign,
sum(ya.daily_spent) as daily_spent
from ya_ads ya
group by 1, 2, 3, 4
order by 1, 2, 3, 4
)
select
tab.date,
tab.source,
tab.medium,
tab.campaign,
sum(((tab.income - tab1.daily_spent) / tab1.daily_spent) * 100.00) as roi
from tab
join tab1
on
tab.date = tab1.date1
and tab.source = tab1.utm_source
and tab.medium = tab1.utm_medium
and tab.campaign = tab1.utm_campaign
group by 1, 2, 3, 4;
*/

--Расчет метрики cpu, cpl, cppu, roi по utm_source:
/*
with tab as (
select
distinct(count(s.visitor_id)) as visitors_count,
s.source,
to_char(s.visit_date, 'yyyy-mm-dd') as date,
count(l.lead_id) as lead_count,
count(l.lead_id) filter(
where l.amount != 0 and l.status_id = 142) as purchase_count,
case when sum(l.amount) is null then 0
else sum(l.amount) end as income
from sessions s
left join leads l
on s.visitor_id = l.visitor_id
group by date, s.source
order by date
), tab1 as (
select
to_char(va.campaign_date, 'yyyy-mm-dd') as date1,
va.utm_source,
sum(va.daily_spent) as daily_spent
from vk_ads va
group by 1, 2
union
select
to_char(ya.campaign_date, 'yyyy-mm-dd'),
ya.utm_source as source,
sum(ya.daily_spent) as daily_spent
from ya_ads ya
group by 1, 2
order by 1, 2
)
select
tab.source,
case when sum(tab1.daily_spent) / sum(tab.visitors_count) is null then 0
else round((sum(tab1.daily_spent) / sum(tab.visitors_count)), 2) end as cpu,
case when sum(tab1.daily_spent) / sum(tab.lead_count) is null then 0
else round((sum(tab1.daily_spent) / sum(tab.lead_count)), 2) end as cpl,
case when sum(tab1.daily_spent) / sum(tab.purchase_count) is null then 0
else round((sum(tab1.daily_spent) / sum(tab.purchase_count)), 2) end as cppu,
case when (sum(tab.income) - sum(tab1.daily_spent) / sum(tab1.daily_spent))
* 100.00 is null then sum(tab.income)
else (sum(tab.income) - sum(tab1.daily_spent) / sum(tab1.daily_spent)) * 100
end as roi
from tab
left join tab1
on tab.source = tab1.utm_source
group by 1
;
*/

--Расчет метрики cpu, cpl, cppu, roi по source, medium и campaign:
/*with tab as (
select
distinct(count(s.visitor_id)) as visitors_count,
to_char(s.visit_date, 'yyyy-mm-dd') as date,
s.source,
s.medium,
s.campaign,
count(l.lead_id) as lead_count,
count(l.lead_id) filter(
where l.amount != 0 and l.status_id = 142) as purchase_count,
case when sum(l.amount) is null then 0
else sum(l.amount) end as income
from sessions s
left join leads l
on s.visitor_id = l.visitor_id
group by 3, 4, 5, 2
), tab1 as (
select
to_char(va.campaign_date, 'yyyy-mm-dd') as date1,
va.utm_source,
va.utm_medium,
va.utm_campaign,
sum(va.daily_spent) as daily_spent
from vk_ads va
group by 2, 3, 4, 1
union
select
to_char(ya.campaign_date, 'yyyy-mm-dd'),
ya.utm_source,
ya.utm_medium,
ya.utm_campaign,
sum(ya.daily_spent) as daily_spent
from ya_ads ya
group by 2, 3, 4, 1
)
select
tab.date,
tab.source,
tab.medium,
tab.campaign,
case when sum(tab1.daily_spent) / sum(tab.visitors_count) is null then 0
else round((sum(tab1.daily_spent) / sum(tab.visitors_count)), 2) end as cpu,
case when sum(tab1.daily_spent) / sum(tab.lead_count) is null then 0
else round((sum(tab1.daily_spent) / sum(tab.lead_count)), 2) end as cpl,
case when sum(tab1.daily_spent) / sum(tab.purchase_count) is null then 0
else round((sum(tab1.daily_spent) / sum(tab.purchase_count)), 2) end as cppu,
case when (sum(tab.income) - sum(tab1.daily_spent) / sum(tab1.daily_spent))
* 100.00 is null then sum(tab.income)
else (sum(tab.income) - sum(tab1.daily_spent) /
sum(tab1.daily_spent)) * 100 end as roi
from tab
left join tab1
on tab.source = tab1.utm_source
and tab.medium = tab1.utm_medium
and tab.campaign = tab1.utm_campaign
group by 2, 3, 4, 1;*/
