## Prerequisites - Setup the environment
  I used Docker as my environment so I could use the Datadog Docker image. After a somewhat failed attempt (see Docker attempt explanation at the end of the file), I attempted the challenge with a Mac instead.

## Collecting Metrics
  1. Host Map Page (Tags)

      After updating my datadog.yaml config file, my host map page looked like this:
      ![Infrastructure Host Map](/screenshots/Screen Shot 2018-04-09 at 10.44.19 AM.png)
      ![Host Map](/screenshots/Screen Shot 2018-04-09 at 10.37.11 AM Updated.png)

      Challenge:
      1. The ```datadog.yaml``` location listed on the Basic Agent Usage site https://docs.datadoghq.com/agent/basic_agent_usage/osx was not the same as the location in my system.
      To find this file, I typed ```datadog-agent status``` to find the location.
      ![Config File](/screenshots/Screen Shot 2018-04-09 at 10.19.27 AM.png)
  2. Postgres Integration

  In my ```postgres.yaml``` file, I added the following settings based on the integration instructions (https://docs.datadoghq.com/integrations/postgres).
  ```
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
  ```

  To check that the integration worked, I looked at the Datadog dashboard and found these two confirmations to be reassuring.
  ![Postgres confirmation](/screenshots/Screen Shot 2018-04-09 at 11.21.52 AM.png)
  ![Postgres integration](/screenshots/Screen Shot 2018-04-09 at 11.22.15 AM.png)

  Challenges:
    1. Running ```psql``` did nothing, because I didn't have a database created. After looking into the question "psql: FATAL: database “<user>” does not exist" by ryanSrich on Stack Overflow, I found Dhananjay's answer of creating the database to be helpful: https://stackoverflow.com/questions/17633422/psql-fatal-database-user-does-not-exist .
    I then looked for the postgres instructions on this: https://www.postgresql.org/docs/9.1/static/app-createdb.html .
    2. Running just ```datadog-agent status``` yielded the following image, which didn't tell me if anything was being sent.
      ![Postgres check](/screenshots/Screen Shot 2018-04-09 at 11.31.21 AM.png)

  3. Setting up a Custom Metric:
    To do this, I followed the instructions on https://docs.datadoghq.com/agent/agent_checks , along with using the ```hello.world``` check as a reference.
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

      3. After fixing Python syntax errors, I got the following chart on my Metrics dashboard, which let me confirm that this metric was working:
        ![My Metric](/screenshots/Screen Shot 2018-04-09 at 1.34.47 PM.png)

      Challenges:
        1. My Python knowledge is pretty basic, but since the datadog status said the Agent was using ```Python Version: 2.7.10```, I looked at the Python Docs for random: https://docs.python.org/2/library/random.html and through trying to fix the error message, I got the right result.
          ![Python Error](/screenshots/Screen Shot 2018-04-09 at 1.29.48 PM.png)

    4. I updated ```custom_metric.yaml``` to:

      ```
      init_config:

      instances:
        - username: datadog
          password: [auto generated password]
          min_collection_interval: 45
      ```

      After reading the way Agent Checks are created https://docs.datadoghq.com/agent/agent_checks, I couldn't figure out how to send it at exactly 45 seconds, but initially, it looked like my checks were around 20 seconds apart. After the yaml update, it seemed to range from 40 to 60 seconds. In the screenshot below, there is a gap for a few minutes because I was trying to change the section and restart the agent.
       ![My Metric_45 seconds](/screenshots/Screen Shot 2018-04-09 at 2.01.22 PM.png)

      Challenge:
        1. I'm not sure if there's a way to get it exactly to 45 seconds, but after trying to see if there were other Datadog methods to do this, I came across	Samantha Drago's response to "How do I change the frequency of an agent check?":  https://help.datadoghq.com/hc/en-us/articles/203557899-How-do-I-change-the-frequency-of-an-agent-check- . Although this check was for http check, which is an integration that I'm not using, the yaml's ```min_collection_interval``` was updated, which was similar to the instructions listed on the Datadog Agent checks docs.

    5. Bonus Question

      I'm unclear on what this question includes as the Python check. It depends if the question is including the yaml file. The approach I followed bypasses the python file and updates the yaml file directly.

## Visualizing Data
  1. The code I wrote for the three charts in the Timeboard is in the custom_timeboard file. To run, enter in the terminal: ```ruby custom_timeboard.rb``` . There were no settings in the timeboard for 5 minutes, so instead I used 4 hours.
  ![Custom Metric Dashboard](/screenshots/Screen Shot 2018-04-09 at 3.55.28 PM.png)
  2. This is what resulted after I annotated by sending it to myself:
  ![Annotation 1](/screenshots/Screen Shot 2018-04-09 at 4.02.00 PM.png)
  ![Annotation 1](/screenshots/Screen Shot 2018-04-09 at 4.02.13 PM.png)
  3. Bonus Question - Anomaly Graph

    According to https://docs.datadoghq.com/monitors/monitor_types/anomaly, the anomaly trend uses past information on the data points to show if it is not within the norm. In my case, it's showing anomalies in the PG commits.


## Monitoring Data
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

  This is one of the warnings that triggered.
  ![Warning Email](/screenshots/Screen Shot 2018-04-09 at 4.36.32 PM.png)

  Bonus Question:
  I set up recurring downtime for the monitor! The UI is really intuitive.

  The setup:
  ![Downtime Weekday](/screenshots/Screen Shot 2018-04-09 at 4.41.01 PM.png)
  ![Downtime Weekend](/screenshots/Screen Shot 2018-04-09 at 4.41.11 PM.png)
  ![Downtime Status](/screenshots/Screen Shot 2018-04-09 at 4.41.21 PM.png)


  Challenge:
  1. It's hard to test the message when it's set for the weekends, because that means waiting out for the email.

## Collecting APM Data
  I rewrote the Flask example to work with Ruby instead. To run, type ```ruby datadog_example.rb```. The biggest challenge for me to get this working was discovering that the trace agent wasn't initialized so nothing was running on port 8162. To fix this, run ```DD_API_KEY=api_key_here /opt/datadog-agent/embedded/bin/trace-agent``` so that each endpoint that is accessed in the datadog_example gets traced properly.

  Sinatra logs:
![Traces from Sinatra](/screenshots/Screen Shot 2018-04-09 at 11.04.13 PM.png)
  Dashboard
![Traces from Sinatra](/screenshots/Screen Shot 2018-04-09 at 10.39.35 PM.png)
![Trace Metrics](/screenshots/Screen Shot 2018-04-09 at 10.41.52 PM.png)

  Link to the dashboard:
  https://p.datadoghq.com/sb/34448073f-c2c78c5d0ed355ca251d5bc225f0ef6d
## Final Question
