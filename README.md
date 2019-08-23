# Function Calling Function with Rest API example

With Geode Functions the default behavior the results are presented to the caller as a collection of results from each server.    That means if each server returns a collection.   So what gets presented is the results are a collection of collections (or whatever the function returns).    With the Geode Client we have options to change up the default result collector to aggregate the results and present the answer as a single collection.    But what about the Geode REST api.

A rest client of the Geode REST api doesn't have Geode client libraries to help out with presenting the results in any other fashion.    So what are we to do?

To quote David Wheeler is "All problems in computer science can be solved by another level of indirection" - and is Geode there is no difference.    We will have a Geode Function running on one server groom the answer from another function.

 

# Example run through

For this example I have started up a Geode system with 3 servers and deployed two functions:

* `PartitionedFunction` - this function just looks up the results for specified keys.   We would call this function with a Geode filter so the function only runs on servers that contain the data that we are interested.   If this runs on more then one server we will get a collection of maps back. 
* `PrettyPrintFunction` - this function takes an argument of what keys to look up.   Since it is an `onRegion` function we need to have it run on one server.    To do that we need to set a filter of one key so it will run on one server that potentially would have that one key.   If we don't set the filter the function will run on every server that has that region.

## What we don't want

In this step we will call the `PartitionedFunction` function as we normally would.   In the result we can see 3 entries from the 3 servers.   One of the servers just happened to be responsible for hosting 2 of the requested filters if it were to host that data.

But that isn't what our end application needs or wants.

```shell script
curl -X POST \
  'http://localhost:7071/geode/v1/functions/PartitionedFunction?onRegion=test&filter=person1,person2,person3,person4' \
  -H 'Content-Type: application/json' \
  -d '[{ "@type" : "string", "@value" : "person1"}, { "@type" : "string", "@value" : "person2"}]'
```
###Result
```shell script
voltron:scripts cblack$ curl -X POST \
>   'http://localhost:7071/geode/v1/functions/PartitionedFunction?onRegion=test&filter=person1,person2,person3,person4' \
>   -H 'Content-Type: application/json' \
>   -d '[{ "@type" : "string", "@value" : "person1"}, { "@type" : "string", "@value" : "person2"}]'
[ {
  "person3" : null
}, {
  "person2" : null
}, {
  "person4" : null,
  "person1" : {
    "@type" : "string",
    "@value" : "person1 value"
  }
} ]voltron:scripts cblack$ 

```
## Call our function

I am going to delete the `person1` key and re-run with our `PrettyPrintFunction`.   Here we can see have a single answer presented.
```
curl -X POST \
  'http://localhost:7071/geode/v1/functions/PrettyPrintFunction?onRegion=test&filter=1' \
  -H 'Content-Type: application/json' \
  -d '[{ "@type" : "string", "@value" : "person1"}, { "@type" : "string", "@value" : "person2"},{ "@type" : "string", "@value" : "person3"}, { "@type" : "string", "@value" : "person4"}]'
```
### Result
```$bash
voltron:scripts cblack$ curl -X POST \
>   'http://localhost:7071/geode/v1/functions/PrettyPrintFunction?onRegion=test&filter=1' \
>   -H 'Content-Type: application/json' \
>   -d '[{ "@type" : "string", "@value" : "person1"}, { "@type" : "string", "@value" : "person2"},{ "@type" : "string", "@value" : "person3"}, { "@type" : "string", "@value" : "person4"}]'
[ {
  "person4" : null,
  "person3" : null,
  "person2" : null,
  "person1" : null
} ]voltron:scripts cblack$ 
```

## Insert a key value
Lets add back in the `person1` key/value.
```
curl -X PUT \
  http://localhost:7071/geode/v1/test/person1 \
  -H 'Content-Type: application/json' \
  -d '{"@type":"string", "@value":"person1 value"}'
```
## Call our function
Here we get the results our application is looking for.
```
curl -X POST \
  'http://localhost:7071/geode/v1/functions/PrettyPrintFunction?onRegion=test&filter=1' \
  -H 'Content-Type: application/json' \
  -d '[{ "@type" : "string", "@value" : "person1"}, { "@type" : "string", "@value" : "person2"},{ "@type" : "string", "@value" : "person3"}, { "@type" : "string", "@value" : "person4"}]'
```
### Result
```
voltron:scripts cblack$ curl -X POST \
>   'http://localhost:7071/geode/v1/functions/PrettyPrintFunction?onRegion=test&filter=1' \
>   -H 'Content-Type: application/json' \
>   -d '[{ "@type" : "string", "@value" : "person1"}, { "@type" : "string", "@value" : "person2"},{ "@type" : "string", "@value" : "person3"}, { "@type" : "string", "@value" : "person4"}]'
[ {
  "person4" : null,
  "person3" : null,
  "person2" : null,
  "person1" : {
    "@type" : "string",
    "@value" : "person1 value"
  }
} ]voltron:scripts cblack$
``` 
