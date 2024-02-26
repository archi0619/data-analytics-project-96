with tab1 as (
    select distinct on (s.visitor_id)
        s.visitor_id,
        s.visit_date,
        l.created_at,
        l.status_id,
        amount,
        lead_id,
        closing_reason,
        medium,
        source,
        campaign
    from sessions as s
    left join leads as l
        on
            s.visitor_id = l.visitor_id
            and s.visit_date <= l.created_at
    where medium != 'organic'
    order by s.visitor_id asc, visit_date desc
), tab as (
    select
        utm_source,
        utm_medium,
        utm_campaign,
        cast(campaign_date as date) as campaign_date,
        sum(daily_spent) as total_cost
    from vk_ads
    group by 1, 2, 3, 4
    union
    select
        utm_source,
        utm_medium,
        utm_campaign,
        cast(campaign_date as date) as campaign_date,
        sum(daily_spent) as total_cost
    from ya_ads
    group by 1, 2, 3, 4
), tab2 as (
    select
        source,
        medium,
        campaign,
        cast(visit_date as date) as visit_date,
        count(visitor_id) as visitors_count,
        count(visitor_id) filter (
            where tab1.created_at is not null
        ) as leads_count,
        count(visitor_id) filter (
            where tab1.status_id = 142
        ) as purchases_count,
        sum(amount) filter (where tab1.status_id = 142) as revenue
    from tab1
    group by source, medium, campaign, cast(visit_date as date)
) select
    to_char(visit_date, 'yyyy-mm-dd') as visit_date,
    visitors_count,
    tab2.source as utm_source,
    tab2.medium as utm_medium,
    tab2.campaign as utm_campaign,
    total_cost,
    leads_count,
    purchases_count,
    revenue
from tab2
left join tab
    on
        tab2.medium = tab.utm_medium
        and tab2.source = tab.utm_source
        and tab2.campaign = tab.utm_campaign
        and tab2.visit_date = tab.campaign_date
where tab2.medium != 'organic'
order by
    9 desc nulls last,
    1 asc,
    visitors_count desc,
    utm_source asc,
    utm_medium asc,
    utm_campaign asc
limit 15;
