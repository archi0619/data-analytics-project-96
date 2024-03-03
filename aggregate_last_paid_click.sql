with tab1 as (
    select distinct on (s.visitor_id)
        s.visitor_id,
        s.visit_date,
        l.created_at,
        l.status_id,
        l.amount,
        l.lead_id,
        l.closing_reason,
        s.medium,
        s.source,
        s.campaign
    from sessions as s
    left join leads as l
        on
           s.visitor_id = l.visitor_id
           and s.visit_date <= l.created_at
    where s.medium != 'organic'
    order by
        s.visitor_id asc,
        s.visit_date desc
)
,
tab as (
    select
        va.utm_source,
        va.utm_medium,
        va.utm_campaign,
        cast(va.campaign_date as date) as campaign_date,
        sum(va.daily_spent) as total_cost
    from vk_ads as va
    group by
        va.utm_source,
        va.utm_medium,
        va.utm_campaign,
        cast(va.campaign_date as date)
    union
    select
        ya.utm_source,
        ya.utm_medium,
        ya.utm_campaign,
        cast(ya.campaign_date as date) as campaign_date,
        sum(ya.daily_spent) as total_cost
    from ya_ads as ya
    group by
        ya.utm_source,
        ya.utm_medium,
        ya.utm_campaign,
        cast(ya.campaign_date as date)
)
,
tab2 as (
    select
        tab1.source,
        tab1.medium,
        tab1.campaign,
        cast(tab1.visit_date as date) as visit_date,
        count(tab1.visitor_id) as visitors_count,
        count(tab1.visitor_id) filter (
            where
        tab1.created_at is not null
        ) as leads_count,
        count(tab1.visitor_id) filter (
            where tab1.status_id = 142
        ) as purchases_count,
        sum(tab1.amount) filter (
            where tab1.status_id = 142
        ) as revenue
    from
        tab1
    group by
        tab1.source,
        tab1.medium,
        tab1.campaign,
        cast(tab1.visit_date as date)
)

select
    to_char(tab2.visit_date, 'yyyy-mm-dd') as visit_date,
    tab2.visitors_count,
    tab2.source as utm_source,
    tab2.medium as utm_medium,
    tab2.campaign as utm_campaign,
    tab.total_cost,
    tab2.leads_count,
    tab2.purchases_count,
    tab2.revenue
from tab2
left join tab
    on
        tab2.medium = tab.utm_medium
        and tab2.source = tab.utm_source
        and tab2.campaign = tab.utm_campaign
        and tab2.visit_date = tab.campaign_date
where tab2.medium != 'organic'
order by
    tab2.revenue desc nulls last,
    tab2.visit_date asc,
    visitors_count desc,
    utm_source asc,
    utm_medium asc,
    utm_campaign asc
limit 15;
