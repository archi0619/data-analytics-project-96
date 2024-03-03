select
	distinct s.visitor_id,
	MAX(s.visit_date) as visit_date,
	s.source as utm_source,
	s.medium as utm_medium,
	s.campaign as utm_campaign,
	l.lead_id,
	l.created_at,
	SUM(l.amount) as amount,
	l.closing_reason,
	l.status_id
from sessions as s
left join leads as l
	using (visitor_id)
where
	s.medium = 'cpc'
	or s.medium = 'cpm'
	or s.medium = 'cpa'
	or s.medium = 'youtube'
	or s.medium = 'cpp'
	or s.medium = 'tg'
	or s.medium = 'social'
group by
	s.visitor_id,
	s.source,
	s.medium,
	s.campaign,
	l.lead_id,
	l.created_at,
	l.closing_reason,
	l.status_id
order by
	amount desc nulls last,
	visit_date asc,
	utm_source
limit 10;
