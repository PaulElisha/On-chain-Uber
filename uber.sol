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

    Reviews[] private reviews;

// the maps

    mapping(uint => TripDetails) internal tripMaps;
    mapping(address => Client) internal clientMaps;
    mapping(address => Driver) internal driverMaps;
    uint256 totalTrips;

  // events
    event DriverProfileCreated(address driver, string driverName, string carModel, bool availability);
    event ClientProfileCreated(address client, string clientName, string location, string destination);
    event TripBooked(address client, uint timestamp, uint id, uint fare, bool started, bool done);
    event TripCompleted(address clientThatPaid, uint fare, bool done, uint timestamp);
    event ReviewDropped(string review, string name);

    //emit TripCompleted(msg.sender, msg.value, destinationReached.done, destinationReached.timestamp);
    
    error Payment_Unsuccessful();
    error Zero_Value_Check();
    error Insufficient_RideFare();
   

// setting up profiles

  // for the drivers
   function zeroAddressCheck(address _address) pure internal {
      assembly {
        if iszero(_address) {
          revert(0,0)
        }
      } 
   }

   function createDriverProfile(string memory _driverName, string memory _carModel) external {
        zeroAddressCheck(msg.sender);

        Driver storage DriverProfile = driverMaps[msg.sender];

        DriverProfile.driverAddress = payable(msg.sender);
        DriverProfile.driverName = _driverName;
        DriverProfile.carModel = _carModel;
        DriverProfile.availability = true;

        emit DriverProfileCreated(DriverProfile.driverAddress, DriverProfile.driverName, DriverProfile.carModel, DriverProfile.availability);
    }
   // for the clients

    function createClientProfile(string memory _name, string memory _location, string memory _destination) external{
      zeroAddressCheck(msg.sender);

      Client storage ClientProfile = clientMaps[msg.sender];

      ClientProfile.clientAddress = payable(msg.sender);
      ClientProfile.clientName = _name;
      ClientProfile.location = _location;
      ClientProfile.destination = _destination;

      emit ClientProfileCreated(ClientProfile.clientAddress, ClientProfile.clientName, ClientProfile.location, ClientProfile.destination);

    }

   //   function getAvailableDrivers() external returns (bool){
   //      Driver storage DriverAvailability = driverMaps[msg.sender];
   //      return(DriverAvailability.availability = true);
   //   }

    function BookTrip() external payable returns (uint tripId){
      if(msg.value < 0) revert Zero_Value_Check();

      TripDetails storage currentTrip = tripMaps[totalTrips];

      currentTrip.clientAddress = payable(msg.sender);
      currentTrip.tripID = totalTrips;
      currentTrip.fare = msg.value;
      currentTrip.timestamp = block.timestamp;
      currentTrip.started = true;
      currentTrip.done = false;

      tripId = totalTrips;
      totalTrips++;

      emit TripBooked(msg.sender, currentTrip.timestamp, tripId, currentTrip.fare, currentTrip.started, currentTrip.done);
    }

    function PayForCompletedTrip(uint256 _tripID) external payable{
      if(msg.value < 0.000002 ether) revert Insufficient_RideFare();
      
      TripDetails storage destinationReached = tripMaps[_tripID];

      destinationReached.done = false;
      destinationReached.timestamp = block.timestamp;

      (bool sent, ) = destinationReached.driverAddress.call{value: msg.value}("");
      if(!sent) revert Payment_Unsuccessful();

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
