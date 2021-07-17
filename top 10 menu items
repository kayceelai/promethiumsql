--Temp table to get top 10 attached items for a Taco sold as ALC (a-la-carte)
with alc_attachments as (
select  m.name, sum(p.count) qty, sum(p.amount) amt from demo.orders p
inner join demo.dim_stores r on p.rest_no=r.rest_no
inner join demo.menu m on p.plunames_key=m.plunames_key
where date_key=20201201
and r.country_nm='USA'
and p.mode_flg=0 -- remove cancelled items
and p.menu_itm_key<>10 -- no need to list Taco again since the goal is to get only attached items
and exists (
--this will get the tickets which has a ALC Taco
select 1 from demo.orders p1
inner join demo.dim_stores r1 on p1.rest_no=r1.rest_no
where p1.date_key=20201201
and r1.country_nm='USA'
and p1.menu_itm_key=10 -- Taco
and p1.sale_valuemeal_uid=-1 --filtering only ALC sold type
and p1.mode_flg=0 -- remove cancelled items
and p.rest_no=p1.rest_no and p.date_key=p1.date_key and p.sale_header_uid=p1.sale_header_uid
)
group by 1
order by 2 desc -- top 10 items based on quantities
limit 10
),
--Temp table to get top 10 attached items for a Taco sold as Combo
combo_attach as(
select  m.name, sum(p.count) qty, sum(p.amount) amt from demo.orders p
inner join demo.dim_stores r on p.rest_no=r.rest_no
inner join demo.menu m on p.plunames_key=m.plunames_key
where date_key=20201201
and r.country_nm='USA'
and p.mode_flg=0 -- remove cancelled items
and p.menu_itm_key<>10
and exists (
  --conditions to get the tickets which has a Taco combo
select 1 from demo.orders p1
inner join demo.dim_stores r1 on p1.rest_no=r1.rest_no
where p1.date_key=20201201
and r1.country_nm='USA'
and p1.menu_itm_key=10
and p1.sale_valuemeal_uid>0 -- this will get Taco sold as Combo
and p1.mode_flg=0 -- no cancelled items
and p.rest_no=p1.rest_no and p.date_key=p1.date_key and p.sale_header_uid=p1.sale_header_uid
)
group by 1
order by 2 desc -- top 10 items based on quantities
limit 10
)
--combine both temp tables
select '1.ALC Top 10 Attachment' category, name, qty, amt from alc_attachments
union all
select '2.Combo Top 10 Attachment' category,  name, qty, amt from combo_attach
order by 1,3 desc