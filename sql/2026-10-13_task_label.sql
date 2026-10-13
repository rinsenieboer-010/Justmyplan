-- Agent-label op taken (2026-10-13)
--
-- tasks.label : kort label van een agent, bijv. "klantportaal" of "school".
--               Wordt als grijs blokje onder de taaknaam getoond.
--
-- Alleen agents mogen het label zetten. Agents schrijven via api/data.js met de
-- service_role-sleutel. De trigger hieronder negeert label-wijzigingen van
-- iedereen anders (app, anon key), zodat het label nooit via de UI of een
-- omweg aangepast kan worden.

alter table public.tasks add column if not exists label text;

create or replace function public.tasks_label_agent_only()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    if tg_op = 'INSERT' then
      new.label := null;
    elsif new.label is distinct from old.label then
      new.label := old.label;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists tasks_label_agent_only on public.tasks;
create trigger tasks_label_agent_only
  before insert or update on public.tasks
  for each row execute function public.tasks_label_agent_only();
