/* 
 * Function to register changes in the binnacle table. It captures INSERT, UPDATE, and DELETE operations.
 * Also updates the 'updated_at' and 'updated_by' fields on the affected table.
 */

create or replace function public.register_changes()
returns trigger
language plpgsql
security definer
as $$
declare
  diff_old jsonb := '{}'::jsonb;
  diff_new jsonb := '{}'::jsonb;
  key text;
  uid uuid := auth.uid();
begin
  -- INSERT
  if (TG_OP = 'INSERT') then
    insert into public.binnacle (object_name, change_type, new_value, user_id)
    values (TG_TABLE_NAME, 'INSERT', to_jsonb(NEW), uid);

    NEW.updated_at := now();
    NEW.updated_by := uid;

    return NEW;

  -- UPDATE
  elsif (TG_OP = 'UPDATE') then
    for key in select jsonb_object_keys(to_jsonb(NEW))
    loop
      if to_jsonb(NEW)->key is distinct from to_jsonb(OLD)->key then
        diff_old := diff_old || jsonb_build_object(key, to_jsonb(OLD)->key);
        diff_new := diff_new || jsonb_build_object(key, to_jsonb(NEW)->key);
      end if;
    end loop;

    insert into public.binnacle (object_name, change_type, old_value, new_value, user_id)
    values (TG_TABLE_NAME, 'UPDATE', diff_old, diff_new, uid);
    
    NEW.updated_at := now();
    NEW.updated_by := uid;

    return NEW;

  -- DELETE
  elsif (TG_OP = 'DELETE') then
    insert into public.binnacle (object_name, change_type, old_value, user_id)
    values (TG_TABLE_NAME, 'DELETE', to_jsonb(OLD), uid);
    return OLD;
  end if;

  return NEW;
end;
$$;

-- Triggers to call the register_changes function on specific tables

-- Trigger for Person table
create trigger trg_person_action
before insert or update or delete
on public.person
for each row
execute function public.register_changes();

-- Trigger for BusinessType table
create trigger trg_businesstype_action
before insert or update or delete
on public.businesstype
for each row
execute function public.register_changes();

-- Trigger for Currency table
create trigger trg_currency_action
before insert or update or delete
on public.currency
for each row
execute function public.register_changes();

-- Trigger for Country table
create trigger trg_country_action
before insert or update or delete
on public.country
for each row
execute function public.register_changes();

-- Trigger for Product table
create trigger trg_product_action
before insert or update or delete
on public.product
for each row
execute function public.register_changes();

-- Trigger for Unit table
create trigger trg_unit_action
before insert or update or delete
on public.unit
for each row
execute function public.register_changes();

-- Trigger for Parameter table
create trigger trg_parameter_action
before insert or update or delete
on public.parameter
for each row
execute function public.register_changes();

-- Trigger for Material table
create trigger trg_material_action
before insert or update or delete
on public.material
for each row
execute function public.register_changes();

-- Trigger for Point table
create trigger trg_point_action
before insert or update or delete
on public.point
for each row
execute function public.register_changes();

-- Trigger for Province table
create trigger trg_province_action
before insert or update or delete
on public.province
for each row
execute function public.register_changes();

-- Trigger for City table
create trigger trg_city_action
before insert or update or delete
on public.city
for each row
execute function public.register_changes();

-- Trigger for District table
create trigger trg_district_action
before insert or update or delete
on public.district
for each row
execute function public.register_changes();

-- Trigger for AffiliatedBussiness table
create trigger trg_affiliatedbussiness_action
before insert or update or delete
on public.affiliatedbussiness
for each row
execute function public.register_changes();

-- Trigger for CollectionCenter table
create trigger trg_collectioncenter_action
before insert or update or delete
on public.collectioncenter
for each row
execute function public.register_changes();

-- Trigger for AffiliatedBusinessXProduct table
create trigger trg_affiliatedbusinessxproduct_action
before insert or update or delete
on public.affiliatedbusinessxproduct
for each row
execute function public.register_changes();

-- Trigger for CollectionCenterXMaterial table
create trigger trg_collectioncenterxmaterial_action
before insert or update or delete
on public.collectioncenterxmaterial
for each row
execute function public.register_changes();

-- Trigger for AffiliatedBusinessTransaction table
create trigger trg_affiliatedbusinesstransaction_action
before insert or update or delete
on public.affiliatedbusinesstransaction
for each row
execute function public.register_changes();

-- Trigger for CollectionCenterTransaction table
create trigger trg_collectioncentertransaction_action
before insert or update or delete
on public.collectioncentertransaction
for each row
execute function public.register_changes();

