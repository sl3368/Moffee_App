Parse.Cloud.afterSave("CoffeeDelivered", function(request, status) {
	// update user similarity table

	username = request.object.get("username");
	coffeeshopid = request.object.get("coffeeshopid");
	var new_unique_delivery = true;

	var uqueryA = new Parse.Query("CoffeeDelivered");
	uqueryA.equalTo("username", username);
	// var uqueryB = new Parse.Query("CoffeeDelivered");
	uqueryA.equalTo("coffeeshopid", coffeeshopid);
	// var unique_delivery = Parse.Query.and(uqueryA, uqueryB);

	uqueryA.count({
		success: function(number) {
			// There are number past orders.
			// status.message("Ordered " + (number - 1) + " times from here before");
			console.log("Ordered " + (number - 1) + " times from here before");
			if (number > 1) {
				response.success("no unique additions to update");
				return;
			} else {
				var counter= 0;

				var query = new Parse.Query("CoffeeDelivered");
				query.equalTo("coffeeshopid", coffeeshopid);
				query.each(function(delivery) {

					var otheruser = delivery.get("username");
					if (otheruser !== username) {
						// increment user similarity in user similarity table
						var queryA = new Parse.Query("UserSimilarity");
						queryA.containedIn("username", [username, otheruser]);
						// var queryB = new Parse.Query("UserSimilarity");
						queryA.containedIn("otherusername", [username, otheruser]);
						// var sim_query = Parse.Query.and(queryA, queryB);

						queryA.first({
							success: function(similarity) {
								if (!similarity) {
									// create a similarity entry
				                    console.log("new similarity");
				                    var UserSimilarity = Parse.Object.extend("UserSimilarity");
									similarity = new UserSimilarity();
				                    similarity.set("username", username);
				                    similarity.set("otherusername", otheruser);
				                    similarity.set("measure", 1);
								} else {
									console.log("update measure");
									similarity.increment("measure");
								}
								similarity.save();
							},
							error: function(error) {
						      // status.error("Uh oh, something went wrong. " + error.message);
						      console.error("Got an error " + error.code + " : " + error.message);
							}
						});
					}

					if (counter % 5 === 0) {
						// Set the  job's progress status
						// status.message(counter + " users processed.");
					}
					counter += 1;

				  }).then(function() {
				    // Set the job's success status
				    // status.success("user similarities updated successfully.");
				  }, function(error) {
				    // Set the job's error status
				    // status.error("Uh oh, something went wrong. " + error.message);
				});		
			}
		},
		error: function(error) {
			new_unique_delivery = false;
			// status.error("Uh oh, something went wrong. " + error.message);
		    console.log("error");
		}
	});
});

Parse.Cloud.job("ComputeRecommendations",function(request,status){
	// user master key
	Parse.Cloud.useMasterKey();


	//Delete all recommendations
	var query = new Parse.Query("Recommendation");
	query.find({ success: function(results) { 
			console.log("Sucessful Deletion of Recommendations!");	
        for(var i=0; i<result.length; i++) {
            result[i].destroy({
                success: function(object) {
                    console.log("Delete job completed");
                    // alert('Delete Successful');
                },
                error: function(object, error) {
                    console.log("Delete error :" + error);
                    // alert('Delete failed');
                }
            });
        }
        console.log("Delete job completed");
	    },
	    error: function(error) {
	        console.log("Error in delete query error: " + error);
	        
	    }
	});
	
	//Query all users and generate a recommendation for each of them
	var simquery = new Parse.Query("UserSimilarity");
	simquery.greaterThan("measure", 1);
	simquery.find({ 
		success: function(results){
		console.log("Queried delivered data!");

		// keeping track of recommended mofers
		var recommended = [];

		for (var j =0; j<results.length; j++){
			//for each delivered data compute
			//compute what are similar values
			var similarity = results[j];
			

			// user 1 & user 2 coffee shops
			var queryjointcoffeeshopidsA = Parse.Query("CoffeeDelivered");
			queryjointcoffeeshopidsA.equalTo("username", results.get("username"));
			var queryjointcoffeeshopidsB = Parse.Query("CoffeeDelivered");
			queryjointcoffeeshopidsB.equalTo("username", results.get("otherusername"));
			var queryjointcoffeeshopids = Parse.Query.or(queryjointcoffeeshopidsA, queryjointcoffeeshopidsB);

			queryjointcoffeeshopids.find({
			    success: function(coffees) {
			        for(var i=0; i<coffees.length; i++) {

			        	// add coffee to both users
			        	
						var queryA = new Parse.Query("UserSimilarity");
						queryA.containedIn("username", [username, otheruser]);
						// var queryB = new Parse.Query("UserSimilarity");
						queryA.containedIn("otherusername", [username, otheruser]);
						// var sim_query = Parse.Query.and(queryA, queryB);

						queryA.first({
							success: function(similarity) {
								if (!similarity) {
									// create a similarity entry
				                    console.log("new similarity");
				                    var UserSimilarity = Parse.Object.extend("UserSimilarity");
									similarity = new UserSimilarity();
				                    similarity.set("username", username);
				                    similarity.set("otherusername", otheruser);
				                    similarity.set("measure", 1);
								} else {
									console.log("update measure");
									similarity.increment("measure");
								}
								similarity.save();
							},
							error: function(error) {
						      // status.error("Uh oh, something went wrong. " + error.message);
						      console.error("Got an error " + error.code + " : " + error.message);
							}
						});
			        }
			        console.log("added recommendations for 1 similarity user");
			    },
			    error: function(error) {
			        console.log("Error in delete query error: " + error);
			        // alert('Error in delete query');
			    }
			});

			//checking if entry has already been in recommended
			var exists = false;
			for(var index=0;index<recommended.length;index++){
				if(recommended[index].get("mofer")==entry.get("mofer")){
					exists = true;
				}	
			}

			//if the user has not already been recommended
			if(!exists){
				
				//first loop through and get all the places for the users
				var coffee_places = []
				for(index=0;index<results.length;index++){
					if(entry.get("mofer")==results[index].get("mofer")){
						coffee_places.push(results[index].get("coffeeshopid"));
					}
				}
		
				//find mofers that have at least one matching coffee shop
				var matching_mofers = []
				for(var k=0;k<results.length;k++){
					
					//check if not candidate
					if(!(results[k].get("mofer")==entry.get("mofer"))){
						
						//check if not already matching
						var matching = false;
						for(var m=0;m<matching_mofers.length;m++){
							if(results[k].get("mofer")==matching_mofers[m].get("mofer")){
								matching=true;
							}
						}

						if(!matching){
							
							//check if matching place
							var matching_place = false;
							for(var p=0;p<coffee_places.length;p++){
								if(results[k].get("coffeeshopid")==coffee_places[p]){
									matching_mofers.push(results[k]);
								}
							}
						}
					}
				}
				
				//add recommendations
				//for every coffee shop
				//in the disjoint set of coffee shops
				//between the matching mofer and the one being recommended to
				
				//for each matching mofer
				for(m=0;m<matching_mofers.length;m++){
					var matched = matching_mofers[m];
							
					//go through results
					for(var h=0;h<results.length;h++){
						if(results[h].get("mofer")==matched.get("mofer")){
								
							//check if this coffeeshop is not already been visited
							var visited=false;
							for(p=0;p<coffee_places.length;p++){
								if(results[h].get("coffeeshopid")==coffee_places[p]){
									visited=true;
								}
							}
							
							console.log("HERE");
														
							//if not visited, then create recommendation
							if(!visited){
								var Rec = Parse.Object.extend("Recommendation");
								var new_rec = new Rec();
								new_rec.set("mofer",entry.get("mofer"));
								new_rec.set("coffeeshopid",results[h].get("coffeeshopid"));
								new_rec.save(null, {
								  success: function(gameScore) {
								    status.message('New object created with objectId: ' + gameScore.id);
								  },
								  error: function(gameScore, error) {
								    status.error('Failed to create new object, with error code: ' + error.message);
								  }
								});	
							}
						}
					}
				}
				

				//add user to recommended list
				recommended.push(entry);
			}
			
		}
		}, error: function(error) {
			console.error("Error in querying coffee delivered");
		}
	});
	status.success("New Recommendations Made!");
});