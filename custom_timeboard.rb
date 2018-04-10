# Custom Metric Dashboard

# Resources:
# https://docs.datadoghq.com/api/?lang=ruby#create-a-timeboard
# https://rubygems.org/gems/dogapi
# https://github.com/bkeepers/dotenv
# https://docs.datadoghq.com/monitors/monitor_types/anomaly/

require 'dotenv'
require 'dogapi'
require 'byebug'
Dotenv.load(".env")

api_key = ENV['datadog_api_key']
app_key = ENV['datadog_app_key']

dog = Dogapi::Client.new(api_key, app_key)

dashboard_title = "Custom Metric Dashboard"
dashboard_description = "Custom Metric Over Host"
graphs = [{
    "title": "My Metric Over Host",
    "viz": "timeseries",
    "definition": {
        "requests": [{
          "q": "max:my_metric{host:Wans-MBP.home}",
        }]
    }
  },
  {
      "title": "Postgresql Commit Anomalies",
      "viz": "timeseries",
      "definition": {
          "requests": [{
            "q": "anomalies(max:postgresql.commits{host:Wans-MBP.home}, 'basic', 2)"
          }]
      }
    },
  {
      "title": "My Metric Over Host With Rollup",
      "viz": "timeseries",
      "definition": {
          "requests": [{
            "q": "avg:my_metric{host:Wans-MBP.home}.rollup(sum, 3600)"
          }]
      }
    }
]

res = dog.create_dashboard(dashboard_title, dashboard_description, graphs, nil)

p "done!"
