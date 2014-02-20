NSPredicate-MongoDB-Adaptor
===========================

This class translates an NSPredicate query into to an appropriate mongodb query encapsulated within an NSDictionary.

The resulting NSDictionary may then be serialised (Using NSJSONSerialization for example) into  a JSON format to be interpreted by mongodb. 

Use cases:
Makes it very easy to construct queries to send to mongodb based backend platforms such as Deployd

##Supported query types:
###logical
-  $not
-  $and
-  $or

###comparison
-  $lt
-  $lte
-  $gt
-  $gte
-  $ne
-  $regex

###membership
-  $in
-  $geoWithin

###javascript
-  $where