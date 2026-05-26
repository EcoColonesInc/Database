/*
 * Function to identify the user who recycled the most material in the previous month
 * and log this information into the userrecycling table. This function is intended to be
 * scheduled to run monthly via a job scheduler.
 */

create or replace function public.user_with_most_recycled()
returns void
language plpgsql
security definer
as $$
declare
  top_record record;
  current_period text := to_char(current_date - interval '1 month', 'YYYY-MM');
begin

  -- Selects the user with the most recycled material in the previous month
  select 
    cct.person_id,
    cct.collection_center_id,
    sum(cct.material_amount) as total_recycled
  into top_record
  from public.collectioncentertransaction cct
  where date_trunc('month', cct.created_at) = date_trunc('month', current_date - interval '1 month')
  group by cct.person_id, cct.collection_center_id
  order by total_recycled desc
  limit 1;

  -- Inserts the record into userrecycling if a user was found
  if top_record is not null then
    insert into public.userrecycling (person_id, collection_center_id, amount_recycle, date)
    values (top_record.person_id, top_record.collection_center_id, top_record.total_recycled, now());
    raise notice 'User with most recycling for month % inserted: %, center %, total %',
      current_period, top_record.person_id, top_record.collection_center_id, top_record.total_recycled;
  else
    raise notice 'No recycling occurred in the previous month (%).', current_period;
  end if;
end;
$$;

/*
 * Job to schedule the user_with_most_recycled function to run monthly
 */

create extension if not exists pg_cron;
select
  cron.schedule(
    'job_user_with_most_recycled',
    '0 0 1 * *',  -- Every month on the 1st at midnight
    $$select public.user_with_most_recycled();$$
  );

