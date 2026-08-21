model (
    enabled false,
    name warehouse.raw_pure_gym.gyms,
    kind full,
    grain (gym_id),
    tags (pure_gym),
    columns (
        gym_id int,
        gym_name varchar,
        status varchar,
        time_zone varchar,
        location__address__line1 varchar,
        location__address__line2 varchar,
        location__address__line3 varchar,
        location__address__town varchar,
        location__address__county varchar,
        location__address__province varchar,
        location__address__postcode varchar,
        location__address__country varchar,
        location__geo_location__longitude decimal(16, 8),
        location__geo_location__latitude decimal(16, 8),
        gym_access__reopen_date date,
        gym_access__access_options__pin_access boolean,
        gym_access__access_options__qr_code_access boolean,
        gym_access__opening_hours__is_always_open boolean,
        gym_access__opening_hours__opening_hours varchar[],
        gym_access__standard_opening_times json,
        contact_info__phone_number varchar,
        contact_info__email_address varchar,
        _dlt_id varchar,
        _dlt_load_id varchar,
        _load_ts timestamp,
    ),
    audits (
        not_null(columns=[
            gym_id,
            _dlt_id,
            _dlt_load_id,
            _load_ts,
        ]),
        unique_values(columns=[
            gym_id,
            _dlt_id,
        ]),
    ),
);


select
    id as gym_id,
    name as gym_name,
    status,
    time_zone,

    location->>'$.Address.Line1' as location__address__line1,
    location->>'$.Address.Line2' as location__address__line2,
    location->>'$.Address.Line3' as location__address__line3,
    location->>'$.Address.Town' as location__address__town,
    location->>'$.Address.County' as location__address__county,
    location->>'$.Address.Province' as location__address__province,
    location->>'$.Address.Postcode' as location__address__postcode,
    location->>'$.Address.Country' as location__address__country,
    location->>'$.GeoLocation.Longitude' as location__geo_location__longitude,
    location->>'$.GeoLocation.Latitude' as location__geo_location__latitude,

    gym_access->>'$.ReopenDate' as gym_access__reopen_date,
    gym_access->>'$.AccessOptions.PinAccess' as gym_access__access_options__pin_access,
    gym_access->>'$.AccessOptions.QrCodeAccess' as gym_access__access_options__qr_code_access,
    gym_access->>'$.OpeningHours.IsAlwaysOpen' as gym_access__opening_hours__is_always_open,
    gym_access->>'$.OpeningHours.OpeningHours' as gym_access__opening_hours__opening_hours,
    gym_access->>'$.StandardOpeningTimes' as gym_access__standard_opening_times,

    contact_info->>'$.PhoneNumber' as contact_info__phone_number,
    contact_info->>'$.EmailAddress' as contact_info__email_address,

    _dlt_id,
    _dlt_load_id,
    @dlt_load_ts(_dlt_load_id) as _load_ts,
from landing.pure_gym.gyms
qualify _load_ts = max(_load_ts) over (partition by gym_id)
order by gym_id
;
