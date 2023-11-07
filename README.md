# sql-cohort-analysis
The cohorts we're classifying by are as follows:

Standard cohorts:
-----------------
 `infrequent`
   users had events on more than 0 and less than 4 days in the respective month
   
 `frequent`
   users had events on more than 3 and less than 8 days in the respective month
   
 `power_user`
   users had events on more than 7 days in the respective month

Special (virtual) cohorts:
--------------------------
 `zombie` (applicable only on this_month)
   users had an event in the month before, but no more event in the current one

 `new` (applicable only on last_month)
   users had their first event in the current month

 `reacquired` (applicable only on last_month)
   users had their first event in a previous month, but were reacquired this      month

Now a table should be created exactly like the one below that shows the amount of user transitions from all cohorts to each other, grouped by year and month - excluding transitions that stayed within the same group. 

Here are two examples, translated to words:

2016-06    | new               | infrequent        | 1135894
=> In June 2016, 1135894 users came into the infrequent cohort that had not been on the site before

2016-06    | frequent          | zombie            | 12487
=> In June 2016, 12487 users did not show up anymore that were frequent users in May.


Context:
--------

- From the events table, the following fields are relevant to you:

 `collector_tstamp`: Time stamp for the event recorded by the collector
 
 `user_id`: Unique ID for a JustWatch site and app user (assume this to be an actual user, ignoring details about cross-device usage)

- Every event in events represents a user interaction

- There might be a few interactions with a NULLed or empty user_ids, please ignore those.
