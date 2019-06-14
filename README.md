# What is this?
This is an example of how one can run a scheduled rolling HBase major compaction on a table with Oozie. The compactions are performed by an `hbase shell` script which will major compact only one reigon per region-server at a time. Further, only regions which have a non-zero cost from a weight function will be compacted by default. Regions will be compacted in priority of those with the highest weight. For those using major compaction to increase data-locality compactions can be forced.

# Steps to deploy a single-shot workflow and reocurring coordinator:
One will deploy the workflow, coordinator and files to HDFS. Then, one will submit the `workflow.properties` to Oozie kicking off compactions.

## Configure and stage files:
1. Modify `example_workflows/workflow.properties` and `example_workflows/coordinator.properties` to match your cluster configuration (look for the items in angle brackets).
2. Modify `example_workflows/coordinator.xml` to match your desired frequency of compaction.
3. Upload `example_workflows` to HDFS (E.g. `hdfs dfs -copyFromLocal `example_workflows` `oozie_compaction`.)

NOTE: `workflow.xml` has a hardcoded `hbase` path of `/usr/bin/hbase` 

## Submit the one-time workflow and run the job:
One can follow the below steps to deploy the workflow:
1. Submit the job via `oozie job -config example_workflows/workflow.properties -run`.
2. One can see that their table was compacted by looking in the action's YARN logs for the string "Done Compacting".

Example output from `yarn logs -applicationId application_######`:
```
Stdoutput Regions to compact for table clay_test:
Stdoutput myhost1.example.com,60200,1556069347115 has 1 region(s) to compact
Stdoutput Compacting myhost1.example.com,60200,1556069347115 region 1d8d46167cdd550b4ac10363c0982191
Heart beat
Heart beat
Stdoutput myhost1.example.com,60200,1556069347115 region 1d8d46167cdd550b4ac10363c0982191
Stdoutput Done compacting in 68.4029998779297 seconds
```

## Submit the scheduled coordinator to regularly run the job:
One can follow the below steps to deploy the coordinator:
1. Submit the job via `oozie job -config example_workflows/coordinators.properties -run` recording the coordinator ID returned.
2. Verify that only one workflow job is running via `oozie job -info <coordinator ID>`

# Steps to run the `rolling_compaction.rb` script by hand

One may run the `rolling_compaction.rb` script manually via:
```
$ export table_name="<your table>"
$ export force_compaction="true|false"
$ ./rolling_compaction.rb
```

If one has an `hbase` binary not at `/usr/bin/hbase`, one can run:
```
$ export table_name="<your table>"
$ export force_compaction="true|false"
$ <path to your hbase binary> shell ./rolling_compaction.rb
