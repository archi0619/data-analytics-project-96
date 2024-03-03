with tab as (
    select
        s.visitor_id,
        s.visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        row_number()
        over (
            partition by s.visitor_id
            order by s.visit_date desc
        )
        as visit_rank
    from sessions as s
    where s.medium != 'organic'
)

select
    t.visitor_id,
    t.visit_date as visit_date,
    t.utm_source,
    t.utm_medium,
    t.utm_campaign,
    l.lead_id,
    l.created_at as created_at,
    l.amount,
    l.closing_reason,
    l.status_id
from tab as t
left join leads as l
    on
        t.visitor_id = l.visitor_id
        and t.visit_date <= l.created_at
where t.visit_rank = 1
order by
    l.amount desc nulls last,
    t.visit_date asc,
    t.utm_source asc,
    t.utm_medium asc,
    t.utm_campaign asc
limit 10;
