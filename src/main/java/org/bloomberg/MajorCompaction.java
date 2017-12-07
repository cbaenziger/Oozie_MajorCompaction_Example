/** * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.bloomberg;

import java.util.List;
import java.util.concurrent.TimeUnit;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.hbase.HBaseConfiguration;
import org.apache.hadoop.hbase.HRegionInfo;
import org.apache.hadoop.hbase.ServerName;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.MetaTableAccessor;
import org.apache.hadoop.hbase.client.Admin;
import org.apache.hadoop.hbase.ClusterStatus;
import org.apache.hadoop.hbase.client.ConnectionFactory;
import org.apache.hadoop.hbase.client.Connection;
import org.apache.hadoop.hbase.client.RegionInfo;
import org.apache.hadoop.hbase.util.Pair;

public class MajorCompaction {

  public static void main(String[] argc) throws Exception {
    Configuration conf = HBaseConfiguration.create();
    conf.addResource(new Path("file:///", System.getProperty("oozie.action.conf.xml")));

    if (System.getenv("HADOOP_TOKEN_FILE_LOCATION") != null) {
      conf.set("mapreduce.job.credentials.binary",
               System.getenv("HADOOP_TOKEN_FILE_LOCATION"));
    }

    Connection connection = ConnectionFactory.createConnection(conf);
    Admin admin = connection.getAdmin();

    System.out.println("Compacting table " + argc[0]);
    TableName tableName = TableName.valueOf(argc[0]);
    MetaTableAccessor mta = new MetaTableAccessor();

    List<Pair<RegionInfo,ServerName>> regionLocations = mta.getTableRegionsAndLocations(tableName);
    for 

    admin.majorCompact(tableName);
    while (admin.getCompactionState(tableName).toString() == "MAJOR") {
      TimeUnit.SECONDS.sleep(10);
      System.out.println("Compacting table " + argc[0]);
    }
    System.out.println("Done compacting table " + argc[0]);
  }
}
