
## Prerequisites - Setup the environment
  I set up the Datadog Agent on my Macbook. I primarily used Ruby, which is why I have a Gemfile set up with the gems that I used.

  I'm using dotenv to store my API Key and APP Key so if anyone wants to run the ruby code that I wrote, set up your ```.env``` file to look like this:
  ```
    datadog_api_key=your_datadog_api_key
    datadog_app_key=your_datadog_app_key
  ```

  Challenge
  1. I originally tried to use Docker as my environment so I could use the Datadog Docker image. While I did get the Datadog image to work as a container, I ran into two issues.
    - First, I didn't know how to get a text editor nor database set up in order to edit the files and database in a later step.
    - Second, I wasn't able to restart the Datadog Agent, which is needed for the later steps as well. This was the error message that I encountered from trying to restart the image:
    ![Datadog Docker Image](/screenshots/datadog_docker_image.png)
    As you can see from this screenshot, when I tried this last week, it indicated that there was an issue moving a file called ```conf.yaml.example``` in ```/etc/datadog-agent/conf.d/docker.d```.
    Instead of trying to spend even longer debugging and trying to understand Docker for this hiring challenge, I switched over my Macbook environment.

## Collecting Metrics
  1. Host Map Page (Tags)

      After updating my datadog.yaml config file, my host map page looked like this:
      ![Infrastructure Host Map](/screenshots/infrastructure_host_map.png)

      ![Host Map](/screenshots/host_map.png)

      Challenge:
      1. The ```datadog.yaml``` location listed on the Basic Agent Usage site https://docs.datadoghq.com/agent/basic_agent_usage/osx was not the same as the location in my system.
      To find this file, I typed ```datadog-agent status``` to find the location of the yaml.
      ![Config File Path](/screenshots/config_file_path.png)

      Instead of being in the ```datadog-agent``` directory, my config file was actually in ```datadog-agent/etc```.
  2. Postgres Integration

        In my ```postgres.yaml``` file, I added the following settings based on the integration instructions (https://docs.datadoghq.com/integrations/postgres).

          init_config:

          instances:
             -   host: localhost
                 port: 5432
                 username: datadog
                 password: [auto generated password]
                 dbname: datadog_test_db
                 tags:
                    - tag_test:tag1
                    - tag_test:tag2
                    - tag_tests

      To check that the integration worked, I looked at the Datadog dashboard and found these two confirmations to be reassuring.
      ![Postgres confirmation](/screenshots/postgres_events_dashboard.png)
      ![Postgres integration](/screenshots/postgres_integration_confirm.png)

       Challenges:

        1. Running ```psql``` did nothing, because I didn't have a database created. After looking into the question "psql: FATAL: database “<user>” does not exist" by ryanSrich on Stack Overflow, I found Dhananjay's answer of creating the database to be helpful: https://stackoverflow.com/questions/17633422/psql-fatal-database-user-does-not-exist . I then looked for the postgres instructions on the docs to see if there might be other tags to care about: https://www.postgresql.org/docs/9.1/static/app-createdb.html . In retrospect, I should also have checked the docs for the postgres version that I am using. Luckily for me, the command didn't change between versions.
        2. Running just ```datadog-agent status``` yielded the following image, which didn't tell me if anything was being sent. This is why my screenshots are of the dashboard on the website.
      ![Postgres check](/screenshots/postgres_term_check.png)

 3. Setting up a Custom Metric:
        To do this, I followed the instructions on https://docs.datadoghq.com/agent/agent_checks , along with using the examples on the page as reference.
       1. In my ```/opt/datadog-agent/etc/conf.d``` directory, I created a file called ```custom_metric.yaml```.
            ```
            init_config:

            instances:
            [{}]
            ```
       2. Then in ```/opt/datadog-agent/etc/checks.d``` I created a file called ```custom_metric.py``` with the following code:
          ```
            import random
            from checks import AgentCheck
            from random import randint
            class CustomMetricCheck(AgentCheck):
                def check(self, instance):
                  self.gauge('my_metric', random.randint(0,1000))
          ```

       3. After fixing Python syntax errors, I got the following chart on my Metrics screen, which let me confirm that this metric was working:
            ![My Metric](/screenshots/my_metric.png)
          Challenge:

          1. My Python knowledge is pretty basic, but since the datadog status said the Agent was using ```Python Version: 2.7.10```, I looked at the Python Docs for random: https://docs.python.org/2/library/random.html and through trying to fix the error messages, I got the right result.
            ![Python Error](/screenshots/python_errors.png)

 4. 45 Second Custom Metrics

      I updated ```custom_metric.yaml``` to:

        ```
        init_config:

        instances:
          - username: datadog
            password: [auto generated password]
            min_collection_interval: 45
        ```

      After reading the way Agent Checks are created https://docs.datadoghq.com/agent/agent_checks, I couldn't figure out how to send it at exactly 45 seconds, but initially, it looked like my checks were around 20 seconds apart. After the yaml update, it seemed to range from 40 to 60 seconds. In the screenshot below, there is a gap for a few minutes because I was trying to change the section and restart the agent.
      ![My Metric_45 seconds](/screenshots/my_metric_45_interval.png)

      Challenge:
      1. I'm not sure if there's a way to get it exactly to 45 seconds, but after trying to see if there were other Datadog methods to do this, I came across	Samantha Drago's response to "How do I change the frequency of an agent check?":  https://help.datadoghq.com/hc/en-us/articles/203557899-How-do-I-change-the-frequency-of-an-agent-check- . Although this check was for http check, which is an integration that I'm not using, the yaml's ```min_collection_interval``` was updated, which was similar to the instructions listed on the Datadog Agent checks docs.

  5. Bonus Question

      I'm unclear on what this question includes as the Python check. It depends if the question is including the yaml file. The approach I followed bypasses the python file and updates the yaml file directly.

## Visualizing Data

  1. The code I wrote for the three charts in the Timeboard is in the ```custom_timeboard.rb``` file. There were no settings in the timeboard for 5 minutes, so instead I used 4 hours in my Timeboard.
    For convenience, here's the code in its entirety:

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
  Dashboard
    ![Custom Metric Dashboard](/screenshots/custom_metrics_dashboard.png)
  Challenge: Since I didn't understand how the query worked, I set up a timeboard with the charts that I wanted and looked at the JSON to determine what my HTTP request needed to look like.

2. This is what resulted after I annotated all the graphs and sent it to myself:
  ![Annotation 1](/screenshots/annotation_1.png)
  ![Annotation 2](/screenshots/annotation_2.png)
3. Bonus Question - Anomaly Graph

    According to https://docs.datadoghq.com/monitors/monitor_types/anomaly, the anomaly trend uses past information on the data points to show if it is not within the norm. In my case, it's showing anomalies in the PG commits.


## Monitoring Data
  To do this, I updated the monitor with the following relevant criteria:
  ![Monitor Settings](/screenshots/monitor_settings.png)

  This is my email template:
  ```
  Hello,

    {{#is_alert}} In the past 5 minutes, my_metric averaged {{value}} on {{host.ip}} !

    Please check the servers! {{/is_alert}}

    {{#is_warning}} In the past 5 minutes, my_metric on average exceeded 500!

    Please monitor the server logs. {{/is_warning}}

    {{#is_no_data}} This is odd, but in the past 10 minutes, there hasn't been any my_metric data.

    Please check the server's connection. {{/is_no_data}}

    @[my email]
  ```

  This is one of the emails that was sent to me.

  ![Warning Email](/screenshots/warning_email.png)

  Bonus Question:
   - I was getting a lot of notifications in a short span of time, so I set up recurring downtime for the monitor! The UI is really intuitive.

   Downtime:
   ![Downtime Weekday](/screenshots/downtime_weekday.png)

   ![Downtime Weekend](/screenshots/downtime_weekend.png)

   ![Downtime Status](/screenshots/downtime_status.png)

   Weekday email for downtime start:
   ![Weekday downtime start](/screenshots/weekday_downtime_start.png)
    Weekday email for downtime end:
   ![Weekday downtime end](/screenshots/weekday_downtime_end.png)

   After seeing this, I think I should have renamed the monitor to not include the host name as a variable.

   Challenge:

   1. It's hard to test the message when it's set for the weekends, because that means waiting out for the email.

## Collecting APM Data
   1. I rewrote the Flask example to work with Ruby instead (without the portion of the code that is logging output), which can be seen in the ```datadog_example.rb``` file. I also ran ```DD_API_KEY=api_key_here /opt/datadog-agent/embedded/bin/trace-agent``` while Sinatra was running. This is the code that's in datadog_example.rb:
        ```
        # This is a rewrite of the flask example from the README.
        # With sinatra and ruby, instead of python

        # Resource
        # http://sinatrarb.com/

        require 'sinatra'
        require 'ddtrace'
        require 'ddtrace/contrib/sinatra/tracer'
        require 'byebug'

        Datadog.configure do |c|
          c.use :sinatra
        end

        get '/' do
          "Entrypoint to the Application"
        end

        get '/api/apm' do
          "Getting APM Started"
        end

        get '/api/trace' do
          "Posting Traces"
        end
       ```
      Sinatra - Terminal:
      ![Traces from Sinatra](/screenshots/sinatra_requests_term.png)
      *Note: I should have included bundle exec, but in this case it didn't affect anything! I haven't used Sinatra in a while.*

      Dashboard
        ![Traces from Sinatra](/screenshots/sinatra_trace_search.png)
        ![Trace Metrics](/screenshots/trace_metrics.png)
      Link to the dashboard: https://p.datadoghq.com/sb/34448073f-c2c78c5d0ed355ca251d5bc225f0ef6d

      Here's a snapshot of the dashboard:
        ![Trace Metrics](/screenshots/dashboard_snapshot.png)
      Challenges:
     
      1. The biggest issue was trying to figure out why port 8126 wasn't working locally. I researched the error message on dd-trace-rb https://github.com/DataDog/dd-trace-rb that I had but only found results relating to Rails. I didn't want to figure out how to deploy my Sinatra app for a production environment, because that would involve setting up the environment again. I didn't quite find an example for my use case, but my search led to the datadog-trace-agent GitHub repo https://github.com/DataDog/datadog-trace-agent and after reading through the repo and the issues, in particular issue 397 https://github.com/DataDog/datadog-trace-agent/issues/397, I realized I needed to activate the tracer to run on port 8126 since starting the Datadog Agent did not turn on the APM Agent.
      2. I also wasn't sure what metrics fell under infrastructure so I picked a few that I think vould be useful.

2. Bonus Question - Difference between Service and Resource

   I read this explanation from Nicholas Muesch in response to "What is the Difference Between "Type", "Service", "Resource", and "Name"?" https://help.datadoghq.com/hc/en-us/articles/115000702546-What-is-the-Difference-Between-Type-Service-Resource-and-Name-

   To rephrase in my own terms, in my case, Sinatra is the service and the endpoints accessed are the resource. A service can be anything that is running the requests while the resource is the action is the being performed by the service.
## Final Question
  After going through this challenge and reading the blog posts on Pokemon Go, Subway System, Restroom Availability, I think a useful way I would want to use Datadog in my life is monitoring the weather. This isn't a particularly creative use of it, because I'm sure people have already done something similar. However, I'd only use it to know if I need an umbrella and rain boots based on the chance of snow or rain by setting up monitoring for precipitation and temperature for forecasted and actual metrics. It's not great to be caught without an umbrella on rainy days, especially when commuting. Knowing whether it'll rain can also prepare someone for a longer commute. It could be useful to keep track of rain/snow metrics and status updates throughout the day with downtime set for non-commute hours, whether it be through an email or dashboard.

## Other
  I like this repo for its markdown formatting explanation: https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet .

### Thanks for reading!
