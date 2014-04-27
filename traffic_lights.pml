#define RED 0
#define GREEN 1

#define WEST_NORTH_REQUEST 0
#define EAST_WEST_REQUEST 1
#define SOUTH_WEST_REQUEST 2
#define NORTH_SOUTH_REQUEST 3

chan traffic_request_queue = [32] of {int};
int traffic_stoped_signal = -1;

int west_north_light, east_west_light, south_west_light, north_south_light = RED;

int west_north_traffic, east_west_traffic, south_west_traffic, north_south_traffic = 0;


chan lock_chan = [1] of {int};

ltl liveness_1 {[]((west_north_traffic == 1) && (west_north_light == RED) -> <>(west_north_light == GREEN))}
ltl liveness_2 {[]((east_west_traffic == 1) && (east_west_light == RED) -> <>(east_west_light == GREEN))}
ltl liveness_3 {[]((south_west_traffic == 1) && (south_west_light == RED) -> <>(south_west_light == GREEN))}
ltl liveness_4 {[]((north_south_traffic == 1) && (north_south_light == RED) -> <>(north_south_light == GREEN))}

ltl fairness_1 {[]<> !((west_north_light) && west_north_traffic)}
ltl fairness_2 {[]<> !((east_west_light) && east_west_traffic)}
ltl fairness_3 {[]<> !((south_west_light) && south_west_traffic)}
ltl fairness_4 {[]<> !((north_south_light) && north_south_traffic)}

proctype west_north_traffic_light() {
    do    
        //wait until competitive directions are blocked with red light
        :: traffic_request_queue ? [WEST_NORTH_REQUEST];
            do
                :: (east_west_light + south_west_light + north_south_light == 0); 
                    west_north_light = GREEN;
                    printf("west-north light is green now\n");
                    break;                          
            od;
            traffic_request_queue ? WEST_NORTH_REQUEST;    
            
            //wait until traffic is stopped
            do
                :: (traffic_stoped_signal == WEST_NORTH_REQUEST); 
                    traffic_stoped_signal = -1;
                    printf("west_north_light is red now\n");
                    west_north_light = RED;
                    break;
            od;   

    od;   
}

proctype east_west_traffic_light() {
    do    
        //wait until competitive directions are blocked with red light
        ::  traffic_request_queue ? [EAST_WEST_REQUEST];
            do
                :: (west_north_light + south_west_light + north_south_light == 0); 
                    east_west_light = GREEN;
                    printf("east-west light is green now\n");  
                    break;
            od;        
            traffic_request_queue ? EAST_WEST_REQUEST;     
                  
            //wait until traffic is stopped
            do
                :: (traffic_stoped_signal == EAST_WEST_REQUEST); 
                    traffic_stoped_signal = -1;
                    printf("east-west light is red now\n");
                    east_west_light = RED;
                    break;
            od;

    od;
}

proctype south_west_traffic_light() {
    do    
        //wait until competitive directions are blocked with red light
        ::  traffic_request_queue ? [SOUTH_WEST_REQUEST];
            do
                :: (west_north_light + east_west_light + north_south_light == 0); 
                    south_west_light = GREEN;
                    printf("south-west light is green now\n");
                    break;   
            od;
            traffic_request_queue ? SOUTH_WEST_REQUEST;   
            
            //wait until traffic is stopped
            do
                :: (traffic_stoped_signal == SOUTH_WEST_REQUEST); 
                    traffic_stoped_signal = -1;
                    printf("south-west light is red now\n");
                    south_west_light = RED;
                    break;
            od;      
           
    od;
}

proctype north_south_traffic_light() {
    do    
        //wait until competitive directions are blocked with red light
        :: traffic_request_queue ? [NORTH_SOUTH_REQUEST];
            do 
                :: (west_north_light + east_west_light + south_west_light == 0); 
                    north_south_light = GREEN;
                    printf("north-south light is green now\n");
                    break;
      
            od;
            traffic_request_queue ? NORTH_SOUTH_REQUEST;  
            
            //wait until traffic is stopped
            do
                :: (traffic_stoped_signal == NORTH_SOUTH_REQUEST); 
                    traffic_stoped_signal = -1;
                    printf("north-south light is red now\n");
                    north_south_light = RED;
                    break;
            od;  
        
    od;
}

proctype traffic_generator() {
    do
        :: (west_north_traffic != 1 && west_north_light == RED);
            printf("--->west-north traffic was started.\n"); 
            west_north_traffic = 1;
            traffic_request_queue ! WEST_NORTH_REQUEST;
           
        :: (east_west_traffic != 1 && east_west_light == RED);
            printf("--->east-west traffic was started.\n"); 
            east_west_traffic = 1;
            traffic_request_queue ! EAST_WEST_REQUEST;
           
        :: (south_west_traffic != 1 && south_west_light == RED);
            printf("--->south-west traffic was started.\n"); 
            south_west_traffic = 1;
            traffic_request_queue ! SOUTH_WEST_REQUEST;
            
        :: (north_south_traffic != 1 && north_south_light == RED);
            printf("--->north-south traffic was started.\n"); 
            north_south_traffic = 1;
            traffic_request_queue ! NORTH_SOUTH_REQUEST;            

        //--------------------stopping traffic--------------------------    
            
        :: (west_north_light == GREEN && west_north_traffic == 1); 
            printf("west-north traffic was stopped.\n"); 
            west_north_traffic = 0;
            traffic_stoped_signal = WEST_NORTH_REQUEST; 
            
        :: (east_west_light == GREEN && east_west_traffic == 1);  
            printf("east-west traffic was stopped.\n"); 
            east_west_traffic = 0;
            traffic_stoped_signal = EAST_WEST_REQUEST;
            
        :: (south_west_light == GREEN && south_west_traffic == 1);  
            printf("south-west traffic was stopped.\n"); 
            south_west_traffic = 0;
            traffic_stoped_signal = SOUTH_WEST_REQUEST;

        :: (north_south_light == GREEN && north_south_traffic == 1);  
            printf("north-south traffic was stopped.\n"); 
            north_south_traffic = 0;
            traffic_stoped_signal = NORTH_SOUTH_REQUEST;                        
    od;
}

proctype verifier() {
    //safety check
    assert(west_north_light + east_west_light + south_west_light + north_south_light < 2);
    
}

init {
    lock_chan ! 1;

    run west_north_traffic_light();
    run east_west_traffic_light();
    run south_west_traffic_light();
    run north_south_traffic_light();
    
    run verifier();

    run traffic_generator();
}
