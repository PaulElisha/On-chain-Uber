// SPDX-License-Identifier: MIT

 pragma solidity 0.8.25;

  contract OnChainUber{
    
    struct TripDetails{
        address payable driverAddress;
        address payable clientAddress;
        uint256 tripID;
        uint256 fare;
        bool started;
        uint timestamp;
        bool done;
    }

    struct Client{
        string clientName;
        address payable clientAddress;
        string location;
        string destination;
        uint256[] clientTripIDs;
    }

    struct Driver{
        string driverName;
        string carModel;
        bool availability;
        address payable driverAddress;
        uint256[] driverTripIDs;
    }

    struct Reviews{
      string comment;
      string name;
    }

    Reviews[] internal reviews;

// the maps

   mapping(uint => TripDetails) internal tripMaps;
   mapping(address => Client) internal clientMaps;
   mapping(address => Driver) internal driverMaps;
   uint256 totalTrips;

// events
   event DriverProfileCreated(address driver, string driverName, string carModel, bool availability);
   event ClientProfileCreated(address client, string clientName, string location, string destination);
   event TripBooked(address driver, address client, uint timestamp, uint id, uint fare, bool started, bool done);
   event TripCompleted(address clientThatPaid, uint fare, bool done, uint timestamp);
   event ReviewDropped(string review, string name);

  //emit TripCompleted(msg.sender, msg.value, destinationReached.done, destinationReached.timestamp);
   
   

// setting up profiles

  // for the drivers

   function createDriverProfile(address _driverAddress, string memory _driverName, string memory _carModel) external payable{
        require(_driverAddress != address(0), "invalid address");
        

        Driver storage DriverProfile = driverMaps[msg.sender];

        DriverProfile.driverAddress = payable (_driverAddress);
        DriverProfile.driverName = _driverName;
        DriverProfile.carModel = _carModel;
        DriverProfile.availability = true;

        emit DriverProfileCreated(DriverProfile.driverAddress, DriverProfile.driverName, DriverProfile.carModel, DriverProfile.availability);
     }
   // for the clients

     function createClientProfile(address _clientAddress, string memory _name, string memory _location, string memory _destination) external{
        require(_clientAddress != address(0), "invalid address");

      Client storage ClientProfile = clientMaps[msg.sender];

      ClientProfile.clientAddress = payable (_clientAddress);
      ClientProfile.clientName = _name;
      ClientProfile.location = _location;
      ClientProfile.destination = _destination;

      emit ClientProfileCreated(ClientProfile.clientAddress, ClientProfile.clientName, ClientProfile.location, ClientProfile.destination);

     }

   //   function getAvailableDrivers() external returns (bool){
   //      Driver storage DriverAvailability = driverMaps[msg.sender];
   //      return(DriverAvailability.availability = true);
   //   }

     function BookTrip() external payable{
        TripDetails storage currentTrip = tripMaps[totalTrips];

        require(msg.value > 0, "the transport fare cannot be less than 0");

        currentTrip.driverAddress = payable(msg.sender);
        currentTrip.clientAddress = payable(msg.sender);
        currentTrip.tripID = totalTrips;
        currentTrip.fare = msg.value;
        currentTrip.timestamp = block.timestamp;
        currentTrip.started = true;
        currentTrip.done = false;

        totalTrips++;

        emit TripBooked(currentTrip.driverAddress, currentTrip.clientAddress, currentTrip.timestamp, currentTrip.tripID, currentTrip.fare, currentTrip.started, currentTrip.done);
     }

     function PayForCompletedTrip(uint256 _tripID) external payable{
      require(msg.value > 0.000002 ether, "a ride goes for 0.000003 and above, nothing less");
      TripDetails storage destinationReached = tripMaps[_tripID];

  

      destinationReached.done = false;
      destinationReached.timestamp = block.timestamp;

      (bool sent, bytes memory data) = destinationReached.driverAddress.call{value: msg.value}("");
      require(sent, "payment not successful, kindly try again");

      Client storage hiredCar = clientMaps[msg.sender];
      hiredCar.clientTripIDs.push(_tripID);

      emit TripCompleted(msg.sender, msg.value, destinationReached.done, destinationReached.timestamp);

     }



// for both to drop reviews

  function TripReview(string memory _comment, string memory _name) external{
  
        reviews.push(Reviews(_comment, _name));

        emit ReviewDropped(_comment, _name);
     }

  function getTripReviews() public view returns (Reviews[] memory) {
    return reviews;
  }


  }
