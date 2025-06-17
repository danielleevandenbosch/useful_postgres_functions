create or replace function public.get_standard_holidays(year int)
    returns table (holiday_date date, name text)
    language plpgsql
as
$$
declare
    d date;
    thanksgiving date;
    float_july date;
    indep_day date;
begin
/*
    author: Daniel L. Van Den Bosch
    date:   2025-06-17
    description: Returns a set of standard holidays for the given year.
                 Adjusts for weekends and ensures no duplicate holidays.
*/
    -- New Year's Day (observed)
    d := make_date(year, 1, 1);
    if extract(dow from d) = 6 then
        d := d - interval '1 day';
    elsif extract(dow from d) = 0 then
        d := d + interval '1 day';
    end if;
    holiday_date := d;
    name := 'New Year''s Day';
    return next;

    -- Memorial Day (last Monday in May)
    d := make_date(year, 5, 31);
    while extract(dow from d) != 1 loop
            d := d - interval '1 day';
        end loop;
    holiday_date := d;
    name := 'Memorial Day';
    return next;

    -- Independence Day (observed)
    indep_day := make_date(year, 7, 4);
    if extract(dow from indep_day) = 6 then
        indep_day := indep_day - interval '1 day';
    elsif extract(dow from indep_day) = 0 then
        indep_day := indep_day + interval '1 day';
    end if;
    holiday_date := indep_day;
    name := 'Independence Day';
    return next;

    -- Floating Holiday near Independence Day (never same as observed date)
    case extract(dow from make_date(year, 7, 4))
        when 2 then  -- Tuesday
        float_july := make_date(year, 7, 3);
        when 4 then  -- Thursday
        float_july := make_date(year, 7, 5);
        else
            float_july := make_date(year, 7, 3);
    end case;

    -- Adjust if floating holiday is weekend
    if extract(dow from float_july) = 6 then
        float_july := float_july - interval '1 day';
    elsif extract(dow from float_july) = 0 then
        float_july := float_july + interval '1 day';
    end if;

    -- Ensure it's not the same as Independence Day (observed)
    if float_july = indep_day then
        float_july := float_july - interval '1 day';
    end if;

    holiday_date := float_july;
    name := 'Floating July Holiday';
    return next;

    -- Labor Day (1st Monday of September)
    d := make_date(year, 9, 1);
    while extract(dow from d) != 1 loop
            d := d + interval '1 day';
        end loop;
    holiday_date := d;
    name := 'Labor Day';
    return next;

    -- Thanksgiving Day (4th Thursday of November)
    d := make_date(year, 11, 1);
    d := d + ((11 - extract(dow from d)) % 7) * interval '1 day' + interval '21 days';
    thanksgiving := d;
    holiday_date := thanksgiving;
    name := 'Thanksgiving Day';
    return next;

    -- Black Friday
    holiday_date := thanksgiving + interval '1 day';
    name := 'Black Friday';
    return next;

    -- Christmas Eve
    d := make_date(year, 12, 24);
    if extract(dow from d) = 6 then
        d := d - interval '1 day';
    elsif extract(dow from d) = 0 then
        d := d - interval '2 days';
    end if;
    holiday_date := d;
    name := 'Christmas Eve';
    return next;

    -- Christmas Day
    d := make_date(year, 12, 25);
    if extract(dow from d) = 6 then
        d := d - interval '1 day';
    elsif extract(dow from d) = 0 then
        d := d + interval '1 day';
    end if;
    holiday_date := d;
    name := 'Christmas Day';
    return next;
end;
$$;

SELECT *
FROM public.get_standard_holidays(2025);

create or replace function mrp.add_business_days
(
    _input_date date
  , _days       smallint
)
returns date
language plpgsql
as
$$
/*
    Author: Daniel L. Van Den Bosch
    Date:   2025-06-17
*/

declare
    direction     int  := case when _days >= 0 then 1 else -1 end;
    abs_days      int  := abs(_days);
    counter       int  := 0;
    work_date     date := _input_date;
    yr_start      int  := extract(year from _input_date)::int;
    yr_end        int  := extract(year from _input_date
                                  + (_days || ' days')::interval)::int;
    holiday_dates date[] := '{}';
begin
    /* gather holidays for every year touched by the span */
    select array_agg(holiday_date)
      into holiday_dates
      from (
              select holiday_date
                from generate_series(least(yr_start, yr_end),
                                     greatest(yr_start, yr_end)) AS yr
                     cross join public.get_standard_holidays(yr)
           ) AS all_holidays;

    /* march forward or backward the requested number of business days */
    while counter < abs_days loop
        work_date := work_date + direction;

        if extract(dow from work_date) not in (0, 6)   -- skip Sat/Sun
           and work_date <> ALL (holiday_dates)        -- skip holidays
        then
            counter := counter + 1;
        end if;
    end loop;

    return work_date;
end;
$$;
