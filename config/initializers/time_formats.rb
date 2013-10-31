#
# Date and Time formats
#
{
  short_date: '%x',
  blog: '%Y-%m-%d',
  rfc822: '%a, %d %b %Y %H:%M:%S %z'
}.each do |k, v|
  Date::DATE_FORMATS[k] = v
  Time::DATE_FORMATS[k] = v
end
