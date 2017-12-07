# What is this?
This is an example of how one can run a scheduled HBase compaction on a table with Oozie.

# To build the JAR:
Simply run the following to build:
`mvn assembly:assembly -DdescriptorId=jar-with-dependencies`

# To deploy workflow:
One will deploy the workflow and files to their HDFS. Then, one will submit the `job.properties` to to Oozie kicking off compactions.

## To stage files on local machine:
1. Put a client `hbase-site.xml` in example_`workflow/lib` directory (or run the shell script in the included `hbase-site.xml` to generate the file.)
2. Copy `target/MajorCompaction-0.0.1-SNAPSHOT-jar-with-dependencies.jar` into `workflow/lib` directory.
3. Modify `example_workflow/job.properties` to match your cluster configuration (look for the items in angle brackets); the values can largely come from your `hbase-site.xml` downloaded in step 1.
5. Upload `example_workflow` to HDFS (E.g. `hdfs dfs -copyFromLocal `example_workflow` `oozie_compaction`.)

## To submit and run the job:
One can follow the below steps to deploy the workflow:
1. Submit the job via `oozie job -config example_workflow/config.xml -run`.
2. One can see that their table was compacted by looking in the action's YARN logs for the string "Done Compacting".
