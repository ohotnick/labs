// MODULE DECLARATION
module scfifo ( data, 
                clock, 
                wrreq, 
                rdreq, 
                aclr, 
                sclr,
                q, 
                usedw, 
                full, 
                empty, 
                almost_full, 
                almost_empty);

// GLOBAL PARAMETER DECLARATION
    parameter lpm_width               = 1;
    parameter lpm_widthu              = 1;
    parameter lpm_numwords            = 2;
    parameter lpm_showahead           = "OFF";
    parameter lpm_type                = "scfifo";
    parameter lpm_hint                = "USE_EAB=ON";
    parameter intended_device_family  = "Stratix";
    parameter underflow_checking      = "ON";
    parameter overflow_checking       = "ON";
    parameter allow_rwcycle_when_full = "OFF";
    parameter use_eab                 = "ON";
    parameter add_ram_output_register = "OFF";
    parameter almost_full_value       = 0;
    parameter almost_empty_value      = 0;
    parameter maximum_depth           = 0;    

// LOCAL_PARAMETERS_BEGIN

    parameter showahead_area          = ((lpm_showahead == "ON")  && (add_ram_output_register == "OFF"));
    parameter showahead_speed         = ((lpm_showahead == "ON")  && (add_ram_output_register == "ON"));
    parameter legacy_speed            = ((lpm_showahead == "OFF") && (add_ram_output_register == "ON"));

// LOCAL_PARAMETERS_END

// INPUT PORT DECLARATION
    input  [lpm_width-1:0] data;
    input  clock;
    input  wrreq;
    input  rdreq;
    input  aclr;
    input  sclr;

// OUTPUT PORT DECLARATION
    output [lpm_width-1:0] q;
    output [lpm_widthu-1:0] usedw;
    output full;
    output empty;
    output almost_full;
    output almost_empty;

// INTERNAL REGISTERS DECLARATION
    reg [lpm_width-1:0] mem_data [(1<<lpm_widthu):0];
    reg [lpm_widthu-1:0] count_id;
    reg [lpm_widthu-1:0] read_id;
    reg [lpm_widthu-1:0] write_id;
    
    wire valid_rreq;
    reg valid_wreq;
    reg write_flag;
    reg full_flag;
    reg empty_flag;
    reg almost_full_flag;
    reg almost_empty_flag;
    reg [lpm_width-1:0] tmp_q;
    reg stratix_family;
    reg set_q_to_x;
    reg set_q_to_x_by_empty;

    reg [lpm_widthu-1:0] write_latency1; 
    reg [lpm_widthu-1:0] write_latency2; 
    reg [lpm_widthu-1:0] write_latency3; 
    integer wrt_count;
        
    reg empty_latency1; 
    reg empty_latency2; 
    
    reg [(1<<lpm_widthu)-1:0] data_ready;
    reg [(1<<lpm_widthu)-1:0] data_shown;
    
// INTERNAL TRI DECLARATION
    tri0 aclr;

// LOCAL INTEGER DECLARATION
    integer i;

// COMPONENT INSTANTIATIONS
    ALTERA_DEVICE_FAMILIES dev ();

// INITIAL CONSTRUCT BLOCK
    initial
    begin

        stratix_family = (dev.FEATURE_FAMILY_STRATIX(intended_device_family));    
        if (lpm_width <= 0)
        begin
            $display ("Error! LPM_WIDTH must be greater than 0.");
            $display ("Time: %0t  Instance: %m", $time);
        end
        if ((lpm_widthu !=1) && (lpm_numwords > (1 << lpm_widthu)))
        begin
            $display ("Error! LPM_NUMWORDS must equal to the ceiling of log2(LPM_WIDTHU).");
            $display ("Time: %0t  Instance: %m", $time);
        end
        if (dev.IS_VALID_FAMILY(intended_device_family) == 0)
        begin
            $display ("Error! Unknown INTENDED_DEVICE_FAMILY=%s.", intended_device_family);
            $display ("Time: %0t  Instance: %m", $time);
        end
        if((add_ram_output_register != "ON") && (add_ram_output_register != "OFF"))
        begin
            $display ("Error! add_ram_output_register must be ON or OFF.");          
            $display ("Time: %0t  Instance: %m", $time);
        end         
        for (i = 0; i < (1<<lpm_widthu); i = i + 1)
        begin
            if (dev.FEATURE_FAMILY_HAS_STRATIXIII_STYLE_RAM(intended_device_family))
                mem_data[i] <= {lpm_width{1'b0}};
            else if (dev.FEATURE_FAMILY_STRATIX(intended_device_family))
            begin
                if ((add_ram_output_register == "ON") || (use_eab == "OFF"))
                    mem_data[i] <= {lpm_width{1'b0}};
                else
                    mem_data[i] <= {lpm_width{1'bx}};
            end
            else
                mem_data[i] <= {lpm_width{1'b0}};
        end

        if (dev.FEATURE_FAMILY_HAS_STRATIXIII_STYLE_RAM(intended_device_family))
            tmp_q <= {lpm_width{1'b0}};
        else if (dev.FEATURE_FAMILY_STRATIX(intended_device_family))
        begin
            if ((add_ram_output_register == "ON") || (use_eab == "OFF"))
                tmp_q <= {lpm_width{1'b0}};
            else    
                tmp_q <= {lpm_width{1'bx}};
        end
        else
            tmp_q <= {lpm_width{1'b0}};
            
        write_flag <= 1'b0;
        count_id <= 0;
        read_id <= 0;
        write_id <= 0;
        full_flag <= 1'b0;
        empty_flag <= 1'b1;
        empty_latency1 <= 1'b1; 
        empty_latency2 <= 1'b1;                 
        set_q_to_x <= 1'b0;
        set_q_to_x_by_empty <= 1'b0;
        wrt_count <= 0;        

        if (almost_full_value == 0)
            almost_full_flag <= 1'b1;
        else
            almost_full_flag <= 1'b0;

        if (almost_empty_value == 0)
            almost_empty_flag <= 1'b0;
        else
            almost_empty_flag <= 1'b1;
    end

    assign valid_rreq = (underflow_checking == "OFF")? rdreq : (rdreq && ~empty_flag);

    always @(wrreq or rdreq or full_flag)
    begin
        if (overflow_checking == "OFF")
            valid_wreq = wrreq;
        else if (allow_rwcycle_when_full == "ON")
                valid_wreq = wrreq && (!full_flag || rdreq);
        else
            valid_wreq = wrreq && !full_flag;
    end

    always @(posedge clock or posedge aclr)
    begin        
        if (aclr)
        begin
            if (add_ram_output_register == "ON")
                tmp_q <= {lpm_width{1'b0}};
            else if ((lpm_showahead == "ON") && (use_eab == "ON"))
            begin
                tmp_q <= {lpm_width{1'bX}};
            end
            else
            begin
                if (!stratix_family)
                begin
                    tmp_q <= {lpm_width{1'b0}};
                end
                else
                    tmp_q <= {lpm_width{1'bX}};
            end

            read_id <= 0;
            count_id <= 0;
            full_flag <= 1'b0;
            empty_flag <= 1'b1;
            empty_latency1 <= 1'b1; 
            empty_latency2 <= 1'b1;
            set_q_to_x <= 1'b0;
            set_q_to_x_by_empty <= 1'b0;
            wrt_count <= 0;
            
            if (almost_full_value > 0)
                almost_full_flag <= 1'b0;
            if (almost_empty_value > 0)
                almost_empty_flag <= 1'b1;

            write_id <= 0;
            
            if ((use_eab == "ON") && (stratix_family) && ((showahead_speed) || (showahead_area) || (legacy_speed)))
            begin
                write_latency1 <= 1'bx;
                write_latency2 <= 1'bx;
                data_shown <= {lpm_width{1'b0}};
                if (add_ram_output_register == "ON")
                    tmp_q <= {lpm_width{1'b0}};
                else
                    tmp_q <= {lpm_width{1'bX}};
            end            
        end
        else
        begin
            if (sclr)
            begin
                if (add_ram_output_register == "ON")
                    tmp_q <= {lpm_width{1'b0}};
                else
                    tmp_q <= {lpm_width{1'bX}};

                read_id <= 0;
                count_id <= 0;
                full_flag <= 1'b0;
                empty_flag <= 1'b1;
                empty_latency1 <= 1'b1; 
                empty_latency2 <= 1'b1;
                set_q_to_x <= 1'b0;
                set_q_to_x_by_empty <= 1'b0;
                wrt_count <= 0;

                if (almost_full_value > 0)
                    almost_full_flag <= 1'b0;
                if (almost_empty_value > 0)
                    almost_empty_flag <= 1'b1;

                if (!stratix_family)
                begin
                    if (valid_wreq)
                    begin
                        write_flag <= 1'b1;
                    end
                    else
                        write_id <= 0;
                end
                else
                begin
                    write_id <= 0;
                end

                if ((use_eab == "ON") && (stratix_family) && ((showahead_speed) || (showahead_area) || (legacy_speed)))
                begin
                    write_latency1 <= 1'bx;
                    write_latency2 <= 1'bx;
                    data_shown <= {lpm_width{1'b0}};                    
                    if (add_ram_output_register == "ON")
                        tmp_q <= {lpm_width{1'b0}};
                    else
                        tmp_q <= {lpm_width{1'bX}};
                end            
            end
            else 
            begin
                //READ operation    
                if (valid_rreq)
                begin
                    if (!(set_q_to_x || set_q_to_x_by_empty))
                    begin  
                        if (!valid_wreq)
                            wrt_count <= wrt_count - 1;

                        if (!valid_wreq)
                        begin
                            full_flag <= 1'b0;

                            if (count_id <= 0)
                                count_id <= {lpm_widthu{1'b1}};
                            else
                                count_id <= count_id - 1;
                        end                

                        if ((use_eab == "ON") && stratix_family && (showahead_speed || showahead_area || legacy_speed))
                        begin
                            if ((wrt_count == 1 && valid_rreq && !valid_wreq) || ((wrt_count == 1 ) && valid_wreq && valid_rreq))
                            begin
                                empty_flag <= 1'b1;
                            end
                            else
                            begin
                                if (showahead_speed)
                                begin
                                    if (data_shown[write_latency2] == 1'b0)
                                    begin
                                        empty_flag <= 1'b1;
                                    end
                                end
                                else if (showahead_area || legacy_speed)
                                begin
                                    if (data_shown[write_latency1] == 1'b0)
                                    begin
                                        empty_flag <= 1'b1;
                                    end
                                end
                            end
                        end
                        else
                        begin
                            if (!valid_wreq)
                            begin
                                if ((count_id == 1) && !(full_flag))
                                    empty_flag <= 1'b1;
                            end
                        end

                        if (empty_flag)
                        begin
                            if (underflow_checking == "ON")
                            begin
                                if ((use_eab == "OFF") || (!stratix_family))
                                    tmp_q <= {lpm_width{1'b0}};
                            end
                            else
                            begin
                                set_q_to_x_by_empty <= 1'b1;
                                $display ("Warning : Underflow occurred! Fifo output is unknown until the next reset is asserted.");
                                $display ("Time: %0t  Instance: %m", $time);
                            end
                        end
                        else if (read_id >= ((1<<lpm_widthu) - 1))
                        begin
                            if (lpm_showahead == "ON")
                            begin
                                if ((use_eab == "ON") && stratix_family && (showahead_speed || showahead_area))                        
                                begin
                                    if (showahead_speed)
                                    begin
                                        if ((write_latency2 == 0) || (data_ready[0] == 1'b1))
                                        begin
                                            if (data_shown[0] == 1'b1)
                                            begin
                                                tmp_q <= mem_data[0];
                                                data_shown[0] <= 1'b0;
                                                data_ready[0] <= 1'b0;
                                            end
                                        end
                                    end
                                    else
                                    begin
                                        if ((count_id == 1) && !(full_flag))
                                        begin
                                            if (underflow_checking == "ON")
                                            begin
                                                if ((use_eab == "OFF") || (!stratix_family))
                                                    tmp_q <= {lpm_width{1'b0}};
                                            end
                                            else
                                                tmp_q <= {lpm_width{1'bX}};
                                        end
                                        else if ((write_latency1 == 0) || (data_ready[0] == 1'b1))
                                        begin
                                            if (data_shown[0] == 1'b1)
                                            begin
                                                tmp_q <= mem_data[0];
                                                data_shown[0] <= 1'b0;
                                                data_ready[0] <= 1'b0;
                                            end
                                        end                            
                                    end
                                end
                                else
                                begin
                                    if ((count_id == 1) && !(full_flag))
                                    begin
                                        if (valid_wreq)
                                            tmp_q <= data;
                                        else
                                            if (underflow_checking == "ON")
                                            begin
                                                if ((use_eab == "OFF") || (!stratix_family))
                                                    tmp_q <= {lpm_width{1'b0}};
                                            end
                                            else
                                                tmp_q <= {lpm_width{1'bX}};
                                    end 
                                    else
                                        tmp_q <= mem_data[0];
                                end
                            end
                            else
                            begin
                                if ((use_eab == "ON") && stratix_family && legacy_speed)
                                begin
                                    if ((write_latency1 == read_id) || (data_ready[read_id] == 1'b1))
                                    begin
                                        if (data_shown[read_id] == 1'b1)
                                        begin
                                            tmp_q <= mem_data[read_id];
                                            data_shown[read_id] <= 1'b0;
                                            data_ready[read_id] <= 1'b0;
                                        end
                                    end
                                    else
                                    begin
                                        tmp_q <= {lpm_width{1'bX}};
                                    end                                  
                                end
                                else
                                    tmp_q <= mem_data[read_id];
                            end

                            read_id <= 0;
                        end // end if (read_id >= ((1<<lpm_widthu) - 1))
                        else
                        begin
                            if (lpm_showahead == "ON")
                            begin
                                if ((use_eab == "ON") && stratix_family && (showahead_speed || showahead_area))
                                begin
                                    if (showahead_speed)
                                    begin
                                        if ((write_latency2 == read_id+1) || (data_ready[read_id+1] == 1'b1))
                                        begin
                                            if (data_shown[read_id+1] == 1'b1)
                                            begin
                                                tmp_q <= mem_data[read_id + 1];
                                                data_shown[read_id+1] <= 1'b0;
                                                data_ready[read_id+1] <= 1'b0;
                                            end
                                        end
                                    end
                                    else
                                    begin
                                        if ((count_id == 1) && !(full_flag))
                                        begin
                                            if (underflow_checking == "ON")
                                            begin
                                                if ((use_eab == "OFF") || (!stratix_family))
                                                    tmp_q <= {lpm_width{1'b0}};
                                            end
                                            else
                                                tmp_q <= {lpm_width{1'bX}};
                                        end
                                        else if ((write_latency1 == read_id+1) || (data_ready[read_id+1] == 1'b1))
                                        begin
                                            if (data_shown[read_id+1] == 1'b1)
                                            begin
                                                tmp_q <= mem_data[read_id + 1];
                                                data_shown[read_id+1] <= 1'b0;
                                                data_ready[read_id+1] <= 1'b0;
                                            end
                                        end
                                    end
                                end
                                else
                                begin
                                    if ((count_id == 1) && !(full_flag))
                                    begin
                                        if ((use_eab == "OFF") && stratix_family)
                                        begin
                                            if (valid_wreq)
                                            begin
                                                tmp_q <= data;
                                            end
                                            else
                                            begin
                                                if (underflow_checking == "ON")
                                                begin
                                                    if ((use_eab == "OFF") || (!stratix_family))
                                                        tmp_q <= {lpm_width{1'b0}};
                                                end
                                                else
                                                    tmp_q <= {lpm_width{1'bX}};
                                            end
                                        end
                                        else
                                        begin
                                            tmp_q <= {lpm_width{1'bX}};
                                        end
                                    end
                                    else
                                        tmp_q <= mem_data[read_id + 1];
                                end
                            end
                            else
                            begin
                                if ((use_eab == "ON") && stratix_family && legacy_speed)
                                begin
                                    if ((write_latency1 == read_id) || (data_ready[read_id] == 1'b1))
                                    begin
                                        if (data_shown[read_id] == 1'b1)
                                        begin
                                            tmp_q <= mem_data[read_id];
                                            data_shown[read_id] <= 1'b0;
                                            data_ready[read_id] <= 1'b0;
                                        end
                                    end
                                    else
                                    begin
                                        tmp_q <= {lpm_width{1'bX}};
                                    end                                
                                end
                                else
                                    tmp_q <= mem_data[read_id];
                            end

                            read_id <= read_id + 1;            
                        end
                    end
                end

                // WRITE operation
                if (valid_wreq)
                begin
                    if (!(set_q_to_x || set_q_to_x_by_empty))
                    begin
                        if (full_flag && (overflow_checking == "OFF"))
                        begin
                            set_q_to_x <= 1'b1;
                            $display ("Warning : Overflow occurred! Fifo output is unknown until the next reset is asserted.");
                            $display ("Time: %0t  Instance: %m", $time);
                        end
                        else
                        begin
                            mem_data[write_id] <= data;
                            write_flag <= 1'b1;
    
                            if (!((use_eab == "ON") && stratix_family && (showahead_speed || showahead_area || legacy_speed)))
                            begin
                                empty_flag <= 1'b0;
                            end
                            else
                            begin
                                empty_latency1 <= 1'b0;
                            end
    
                            if (!valid_rreq)                
                                wrt_count <= wrt_count + 1;
    
                            if (!valid_rreq)
                            begin
                                if (count_id >= (1 << lpm_widthu) - 1)
                                    count_id <= 0;
                                else
                                    count_id <= count_id + 1;               
                            end
                            else
                            begin
                                if (allow_rwcycle_when_full == "OFF")
                                    full_flag <= 1'b0;
                            end
    
                            if (!(stratix_family) || (stratix_family && !(showahead_speed || showahead_area || legacy_speed)))
                            begin                
                                if (!valid_rreq)
                                    if ((count_id == lpm_numwords - 1) && (empty_flag == 1'b0))
                                        full_flag <= 1'b1;
                            end
                            else
                            begin   
                                if (!valid_rreq)
                                    if (count_id == lpm_numwords - 1)
                                        full_flag <= 1'b1;
                            end
    
                            if (lpm_showahead == "ON")
                            begin
                                if ((use_eab == "ON") && stratix_family && (showahead_speed || showahead_area))
                                begin
                                    write_latency1 <= write_id;                    
                                    data_shown[write_id] <= 1'b1;
                                    data_ready[write_id] <= 1'bx;
                                end
                                else
                                begin 
                                    if ((use_eab == "OFF") && stratix_family && (count_id == 0) && (!full_flag))
                                    begin
                                        tmp_q <= data;
                                    end
                                    else
                                    begin
                                        if ((!empty_flag) && (!valid_rreq))
                                        begin
                                            tmp_q <= mem_data[read_id];
                                        end
                                    end
                                end
                            end
                            else
                            begin
                                if ((use_eab == "ON") && stratix_family && legacy_speed) 
                                begin
                                    write_latency1 <= write_id;                    
                                    data_shown[write_id] <= 1'b1;
                                    data_ready[write_id] <= 1'bx;
                                end
                            end
                        end
                    end   
                end    

                if (almost_full_value == 0)
                    almost_full_flag <= 1'b1;
                else if (lpm_numwords > almost_full_value)
                begin
                    if (almost_full_flag)
                    begin
                        if ((count_id == almost_full_value) && !wrreq && rdreq)
                            almost_full_flag <= 1'b0;
                    end
                    else
                    begin
                        if ((almost_full_value == 1) && (count_id == 0) && wrreq)
                            almost_full_flag <= 1'b1;
                        else if ((almost_full_value > 1) && (count_id == almost_full_value - 1)
                                && wrreq && !rdreq)
                            almost_full_flag <= 1'b1;
                    end
                end

                if (almost_empty_value == 0)
                    almost_empty_flag <= 1'b0;
                else if (lpm_numwords > almost_empty_value)
                begin
                    if (almost_empty_flag)
                    begin
                        if ((almost_empty_value == 1) && (count_id == 0) && wrreq)
                            almost_empty_flag <= 1'b0;
                        else if ((almost_empty_value > 1) && (count_id == almost_empty_value - 1)
                                && wrreq && !rdreq)
                            almost_empty_flag <= 1'b0;
                    end
                    else
                    begin
                        if ((count_id == almost_empty_value) && !wrreq && rdreq)
                            almost_empty_flag <= 1'b1;
                    end
                end
            end

            if ((use_eab == "ON") && stratix_family)
            begin
                if (showahead_speed)
                begin
                    write_latency2 <= write_latency1;
                    write_latency3 <= write_latency2;
                    if (write_latency3 !== write_latency2)
                        data_ready[write_latency2] <= 1'b1;
                                    
                    empty_latency2 <= empty_latency1;

                    if (data_shown[write_latency2]==1'b1)
                    begin
                        if ((read_id == write_latency2) || aclr || sclr)
                        begin
                            if (!(aclr === 1'b1) && !(sclr === 1'b1))                        
                            begin
                                if (write_latency2 !== 1'bx)
                                begin
                                    tmp_q <= mem_data[write_latency2];
                                    data_shown[write_latency2] <= 1'b0;
                                    data_ready[write_latency2] <= 1'b0;
    
                                    if (!valid_rreq)
                                        empty_flag <= empty_latency2;
                                end
                            end
                        end
                    end
                end
                else if (showahead_area)
                begin
                    write_latency2 <= write_latency1;
                    if (write_latency2 !== write_latency1)
                        data_ready[write_latency1] <= 1'b1;

                    if (data_shown[write_latency1]==1'b1)
                    begin
                        if ((read_id == write_latency1) || aclr || sclr)
                        begin
                            if (!(aclr === 1'b1) && !(sclr === 1'b1))
                            begin
                                if (write_latency1 !== 1'bx)
                                begin
                                    tmp_q <= mem_data[write_latency1];
                                    data_shown[write_latency1] <= 1'b0;
                                    data_ready[write_latency1] <= 1'b0;

                                    if (!valid_rreq)
                                    begin
                                        empty_flag <= empty_latency1;
                                    end
                                end
                            end
                        end
                    end                            
                end
                else
                begin
                    if (legacy_speed)
                    begin
                        write_latency2 <= write_latency1;
                        if (write_latency2 !== write_latency1)
                            data_ready[write_latency1] <= 1'b1;

                            empty_flag <= empty_latency1;

                        if ((wrt_count == 1 && !valid_wreq && valid_rreq) || aclr || sclr)
                        begin
                            empty_flag <= 1'b1;
                            empty_latency1 <= 1'b1;
                        end
                        else
                        begin
                            if ((wrt_count == 1) && valid_wreq && valid_rreq)
                            begin
                                empty_flag <= 1'b1;
                            end
                        end
                    end
                end
            end
        end
    end

    always @(negedge clock)
    begin
        if (write_flag)
        begin
            write_flag <= 1'b0;

            if (sclr || aclr || (write_id >= ((1 << lpm_widthu) - 1)))
                write_id <= 0;
            else
                write_id <= write_id + 1;
        end

        if (!(stratix_family))
        begin
            if (!empty)
            begin
                if ((lpm_showahead == "ON") && ($time > 0))
                    tmp_q <= mem_data[read_id];
            end
        end
    end

    always @(full_flag)
    begin
        if (lpm_numwords == almost_full_value)
            if (full_flag)
                almost_full_flag = 1'b1;
            else
                almost_full_flag = 1'b0;

        if (lpm_numwords == almost_empty_value)
            if (full_flag)
                almost_empty_flag = 1'b0;
            else
                almost_empty_flag = 1'b1;
    end

// CONTINOUS ASSIGNMENT   
    assign q = (set_q_to_x || set_q_to_x_by_empty)? {lpm_width{1'bX}} : tmp_q;
    assign full = (set_q_to_x || set_q_to_x_by_empty)? 1'bX : full_flag;
    assign empty = (set_q_to_x || set_q_to_x_by_empty)? 1'bX : empty_flag;
    assign usedw = (set_q_to_x || set_q_to_x_by_empty)? {lpm_widthu{1'bX}} : count_id;
    assign almost_full = (set_q_to_x || set_q_to_x_by_empty)? 1'bX : almost_full_flag;
    assign almost_empty = (set_q_to_x || set_q_to_x_by_empty)? 1'bX : almost_empty_flag;

endmodule // scfifo
// END OF MODULE
    
//--------------------------------------------------------------------------
// Module Name      : altshift_taps
//
// Description      : Parameterized shift register with taps megafunction.
//                    Implements a RAM-based shift register for efficient
//                    creation of very large shift registers
//
// Limitation       : This megafunction is provided only for backward
//                    compatibility in Cyclone, Stratix, and Stratix GX
//                    designs.
//
// Results expected : Produce output from the end of the shift register
//                    and from the regularly spaced taps along the
//                    shift register.
//

//START_MODULE_NAME------------------------------------------------------------
//
// Module Name     :  ALTERA_DEVICE_FAMILIES
//
// Description     :  Common Altera device families comparison
//
// Limitation      :
//
// Results expected:
//
//END_MODULE_NAME--------------------------------------------------------------

// BEGINNING OF MODULE
`timescale 1 ps / 1 ps

// MODULE DECLARATION
module ALTERA_DEVICE_FAMILIES;

function IS_FAMILY_ARRIAGX;
    input[8*20:1] device;
    reg is_arriagx;
begin
    if ((device == "Arria GX") || (device == "ARRIA GX") || (device == "arria gx") || (device == "ArriaGX") || (device == "ARRIAGX") || (device == "arriagx") || (device == "Stratix II GX Lite") || (device == "STRATIX II GX LITE") || (device == "stratix ii gx lite") || (device == "StratixIIGXLite") || (device == "STRATIXIIGXLITE") || (device == "stratixiigxlite"))
        is_arriagx = 1;
    else
        is_arriagx = 0;

    IS_FAMILY_ARRIAGX  = is_arriagx;
end
endfunction //IS_FAMILY_ARRIAGX

function IS_FAMILY_ARRIAIIGX;
    input[8*20:1] device;
    reg is_arriaiigx;
begin
    if ((device == "Arria II GX") || (device == "ARRIA II GX") || (device == "arria ii gx") || (device == "ArriaIIGX") || (device == "ARRIAIIGX") || (device == "arriaiigx") || (device == "Arria IIGX") || (device == "ARRIA IIGX") || (device == "arria iigx") || (device == "ArriaII GX") || (device == "ARRIAII GX") || (device == "arriaii gx") || (device == "Arria II") || (device == "ARRIA II") || (device == "arria ii") || (device == "ArriaII") || (device == "ARRIAII") || (device == "arriaii") || (device == "Arria II (GX/E)") || (device == "ARRIA II (GX/E)") || (device == "arria ii (gx/e)") || (device == "ArriaII(GX/E)") || (device == "ARRIAII(GX/E)") || (device == "arriaii(gx/e)") || (device == "PIRANHA") || (device == "piranha"))
        is_arriaiigx = 1;
    else
        is_arriaiigx = 0;

    IS_FAMILY_ARRIAIIGX  = is_arriaiigx;
end
endfunction //IS_FAMILY_ARRIAIIGX

function IS_FAMILY_ARRIAIIGZ;
    input[8*20:1] device;
    reg is_arriaiigz;
begin
    if ((device == "Arria II GZ") || (device == "ARRIA II GZ") || (device == "arria ii gz") || (device == "ArriaII GZ") || (device == "ARRIAII GZ") || (device == "arriaii gz") || (device == "Arria IIGZ") || (device == "ARRIA IIGZ") || (device == "arria iigz") || (device == "ArriaIIGZ") || (device == "ARRIAIIGZ") || (device == "arriaiigz"))
        is_arriaiigz = 1;
    else
        is_arriaiigz = 0;

    IS_FAMILY_ARRIAIIGZ  = is_arriaiigz;
end
endfunction //IS_FAMILY_ARRIAIIGZ

function IS_FAMILY_ARRIAVGZ;
    input[8*20:1] device;
    reg is_arriavgz;
begin
    if ((device == "Arria V GZ") || (device == "ARRIA V GZ") || (device == "arria v gz") || (device == "ArriaVGZ") || (device == "ARRIAVGZ") || (device == "arriavgz"))
        is_arriavgz = 1;
    else
        is_arriavgz = 0;

    IS_FAMILY_ARRIAVGZ  = is_arriavgz;
end
endfunction //IS_FAMILY_ARRIAVGZ

function IS_FAMILY_ARRIAV;
    input[8*20:1] device;
    reg is_arriav;
begin
    if ((device == "Arria V") || (device == "ARRIA V") || (device == "arria v") || (device == "Arria V (GT/GX)") || (device == "ARRIA V (GT/GX)") || (device == "arria v (gt/gx)") || (device == "ArriaV(GT/GX)") || (device == "ARRIAV(GT/GX)") || (device == "arriav(gt/gx)") || (device == "ArriaV") || (device == "ARRIAV") || (device == "arriav") || (device == "Arria V (GT/GX/ST/SX)") || (device == "ARRIA V (GT/GX/ST/SX)") || (device == "arria v (gt/gx/st/sx)") || (device == "ArriaV(GT/GX/ST/SX)") || (device == "ARRIAV(GT/GX/ST/SX)") || (device == "arriav(gt/gx/st/sx)") || (device == "Arria V (GT)") || (device == "ARRIA V (GT)") || (device == "arria v (gt)") || (device == "ArriaV(GT)") || (device == "ARRIAV(GT)") || (device == "arriav(gt)") || (device == "Arria V (GX)") || (device == "ARRIA V (GX)") || (device == "arria v (gx)") || (device == "ArriaV(GX)") || (device == "ARRIAV(GX)") || (device == "arriav(gx)") || (device == "Arria V (ST)") || (device == "ARRIA V (ST)") || (device == "arria v (st)") || (device == "ArriaV(ST)") || (device == "ARRIAV(ST)") || (device == "arriav(st)") || (device == "Arria V (SX)") || (device == "ARRIA V (SX)") || (device == "arria v (sx)") || (device == "ArriaV(SX)") || (device == "ARRIAV(SX)") || (device == "arriav(sx)"))
        is_arriav = 1;
    else
        is_arriav = 0;

    IS_FAMILY_ARRIAV  = is_arriav;
end
endfunction //IS_FAMILY_ARRIAV

function IS_FAMILY_ARRIAVI;
    input[8*20:1] device;
    reg is_arriavi;
begin
    if ((device == "Arria VI") || (device == "ARRIA VI") || (device == "arria vi") || (device == "ArriaVI") || (device == "ARRIAVI") || (device == "arriavi"))
        is_arriavi = 1;
    else
        is_arriavi = 0;

    IS_FAMILY_ARRIAVI  = is_arriavi;
end
endfunction //IS_FAMILY_ARRIAVI

function IS_FAMILY_CYCLONEII;
    input[8*20:1] device;
    reg is_cycloneii;
begin
    if ((device == "Cyclone II") || (device == "CYCLONE II") || (device == "cyclone ii") || (device == "Cycloneii") || (device == "CYCLONEII") || (device == "cycloneii") || (device == "Magellan") || (device == "MAGELLAN") || (device == "magellan") || (device == "CycloneII") || (device == "CYCLONEII") || (device == "cycloneii"))
        is_cycloneii = 1;
    else
        is_cycloneii = 0;

    IS_FAMILY_CYCLONEII  = is_cycloneii;
end
endfunction //IS_FAMILY_CYCLONEII

function IS_FAMILY_CYCLONEIIILS;
    input[8*20:1] device;
    reg is_cycloneiiils;
begin
    if ((device == "Cyclone III LS") || (device == "CYCLONE III LS") || (device == "cyclone iii ls") || (device == "CycloneIIILS") || (device == "CYCLONEIIILS") || (device == "cycloneiiils") || (device == "Cyclone III LPS") || (device == "CYCLONE III LPS") || (device == "cyclone iii lps") || (device == "Cyclone LPS") || (device == "CYCLONE LPS") || (device == "cyclone lps") || (device == "CycloneLPS") || (device == "CYCLONELPS") || (device == "cyclonelps") || (device == "Tarpon") || (device == "TARPON") || (device == "tarpon") || (device == "Cyclone IIIE") || (device == "CYCLONE IIIE") || (device == "cyclone iiie"))
        is_cycloneiiils = 1;
    else
        is_cycloneiiils = 0;

    IS_FAMILY_CYCLONEIIILS  = is_cycloneiiils;
end
endfunction //IS_FAMILY_CYCLONEIIILS

function IS_FAMILY_CYCLONEIII;
    input[8*20:1] device;
    reg is_cycloneiii;
begin
    if ((device == "Cyclone III") || (device == "CYCLONE III") || (device == "cyclone iii") || (device == "CycloneIII") || (device == "CYCLONEIII") || (device == "cycloneiii") || (device == "Barracuda") || (device == "BARRACUDA") || (device == "barracuda") || (device == "Cuda") || (device == "CUDA") || (device == "cuda") || (device == "CIII") || (device == "ciii"))
        is_cycloneiii = 1;
    else
        is_cycloneiii = 0;

    IS_FAMILY_CYCLONEIII  = is_cycloneiii;
end
endfunction //IS_FAMILY_CYCLONEIII

function IS_FAMILY_CYCLONEIVE;
    input[8*20:1] device;
    reg is_cycloneive;
begin
    if ((device == "Cyclone IV E") || (device == "CYCLONE IV E") || (device == "cyclone iv e") || (device == "CycloneIV E") || (device == "CYCLONEIV E") || (device == "cycloneiv e") || (device == "Cyclone IVE") || (device == "CYCLONE IVE") || (device == "cyclone ive") || (device == "CycloneIVE") || (device == "CYCLONEIVE") || (device == "cycloneive"))
        is_cycloneive = 1;
    else
        is_cycloneive = 0;

    IS_FAMILY_CYCLONEIVE  = is_cycloneive;
end
endfunction //IS_FAMILY_CYCLONEIVE

function IS_FAMILY_CYCLONEIVGX;
    input[8*20:1] device;
    reg is_cycloneivgx;
begin
    if ((device == "Cyclone IV GX") || (device == "CYCLONE IV GX") || (device == "cyclone iv gx") || (device == "Cyclone IVGX") || (device == "CYCLONE IVGX") || (device == "cyclone ivgx") || (device == "CycloneIV GX") || (device == "CYCLONEIV GX") || (device == "cycloneiv gx") || (device == "CycloneIVGX") || (device == "CYCLONEIVGX") || (device == "cycloneivgx") || (device == "Cyclone IV") || (device == "CYCLONE IV") || (device == "cyclone iv") || (device == "CycloneIV") || (device == "CYCLONEIV") || (device == "cycloneiv") || (device == "Cyclone IV (GX)") || (device == "CYCLONE IV (GX)") || (device == "cyclone iv (gx)") || (device == "CycloneIV(GX)") || (device == "CYCLONEIV(GX)") || (device == "cycloneiv(gx)") || (device == "Cyclone III GX") || (device == "CYCLONE III GX") || (device == "cyclone iii gx") || (device == "CycloneIII GX") || (device == "CYCLONEIII GX") || (device == "cycloneiii gx") || (device == "Cyclone IIIGX") || (device == "CYCLONE IIIGX") || (device == "cyclone iiigx") || (device == "CycloneIIIGX") || (device == "CYCLONEIIIGX") || (device == "cycloneiiigx") || (device == "Cyclone III GL") || (device == "CYCLONE III GL") || (device == "cyclone iii gl") || (device == "CycloneIII GL") || (device == "CYCLONEIII GL") || (device == "cycloneiii gl") || (device == "Cyclone IIIGL") || (device == "CYCLONE IIIGL") || (device == "cyclone iiigl") || (device == "CycloneIIIGL") || (device == "CYCLONEIIIGL") || (device == "cycloneiiigl") || (device == "Stingray") || (device == "STINGRAY") || (device == "stingray"))
        is_cycloneivgx = 1;
    else
        is_cycloneivgx = 0;

    IS_FAMILY_CYCLONEIVGX  = is_cycloneivgx;
end
endfunction //IS_FAMILY_CYCLONEIVGX

function IS_FAMILY_CYCLONEV;
    input[8*20:1] device;
    reg is_cyclonev;
begin
    if ((device == "Cyclone V") || (device == "CYCLONE V") || (device == "cyclone v") || (device == "CycloneV") || (device == "CYCLONEV") || (device == "cyclonev") || (device == "Cyclone V (GT/GX/E/SX)") || (device == "CYCLONE V (GT/GX/E/SX)") || (device == "cyclone v (gt/gx/e/sx)") || (device == "CycloneV(GT/GX/E/SX)") || (device == "CYCLONEV(GT/GX/E/SX)") || (device == "cyclonev(gt/gx/e/sx)") || (device == "Cyclone V (E/GX/GT/SX/SE/ST)") || (device == "CYCLONE V (E/GX/GT/SX/SE/ST)") || (device == "cyclone v (e/gx/gt/sx/se/st)") || (device == "CycloneV(E/GX/GT/SX/SE/ST)") || (device == "CYCLONEV(E/GX/GT/SX/SE/ST)") || (device == "cyclonev(e/gx/gt/sx/se/st)") || (device == "Cyclone V (E)") || (device == "CYCLONE V (E)") || (device == "cyclone v (e)") || (device == "CycloneV(E)") || (device == "CYCLONEV(E)") || (device == "cyclonev(e)") || (device == "Cyclone V (GX)") || (device == "CYCLONE V (GX)") || (device == "cyclone v (gx)") || (device == "CycloneV(GX)") || (device == "CYCLONEV(GX)") || (device == "cyclonev(gx)") || (device == "Cyclone V (GT)") || (device == "CYCLONE V (GT)") || (device == "cyclone v (gt)") || (device == "CycloneV(GT)") || (device == "CYCLONEV(GT)") || (device == "cyclonev(gt)") || (device == "Cyclone V (SX)") || (device == "CYCLONE V (SX)") || (device == "cyclone v (sx)") || (device == "CycloneV(SX)") || (device == "CYCLONEV(SX)") || (device == "cyclonev(sx)") || (device == "Cyclone V (SE)") || (device == "CYCLONE V (SE)") || (device == "cyclone v (se)") || (device == "CycloneV(SE)") || (device == "CYCLONEV(SE)") || (device == "cyclonev(se)") || (device == "Cyclone V (ST)") || (device == "CYCLONE V (ST)") || (device == "cyclone v (st)") || (device == "CycloneV(ST)") || (device == "CYCLONEV(ST)") || (device == "cyclonev(st)"))
        is_cyclonev = 1;
    else
        is_cyclonev = 0;

    IS_FAMILY_CYCLONEV  = is_cyclonev;
end
endfunction //IS_FAMILY_CYCLONEV

function IS_FAMILY_CYCLONE;
    input[8*20:1] device;
    reg is_cyclone;
begin
    if ((device == "Cyclone") || (device == "CYCLONE") || (device == "cyclone") || (device == "ACEX2K") || (device == "acex2k") || (device == "ACEX 2K") || (device == "acex 2k") || (device == "Tornado") || (device == "TORNADO") || (device == "tornado"))
        is_cyclone = 1;
    else
        is_cyclone = 0;

    IS_FAMILY_CYCLONE  = is_cyclone;
end
endfunction //IS_FAMILY_CYCLONE

function IS_FAMILY_HARDCOPYII;
    input[8*20:1] device;
    reg is_hardcopyii;
begin
    if ((device == "HardCopy II") || (device == "HARDCOPY II") || (device == "hardcopy ii") || (device == "HardCopyII") || (device == "HARDCOPYII") || (device == "hardcopyii") || (device == "Fusion") || (device == "FUSION") || (device == "fusion"))
        is_hardcopyii = 1;
    else
        is_hardcopyii = 0;

    IS_FAMILY_HARDCOPYII  = is_hardcopyii;
end
endfunction //IS_FAMILY_HARDCOPYII

function IS_FAMILY_HARDCOPYIII;
    input[8*20:1] device;
    reg is_hardcopyiii;
begin
    if ((device == "HardCopy III") || (device == "HARDCOPY III") || (device == "hardcopy iii") || (device == "HardCopyIII") || (device == "HARDCOPYIII") || (device == "hardcopyiii") || (device == "HCX") || (device == "hcx"))
        is_hardcopyiii = 1;
    else
        is_hardcopyiii = 0;

    IS_FAMILY_HARDCOPYIII  = is_hardcopyiii;
end
endfunction //IS_FAMILY_HARDCOPYIII

function IS_FAMILY_HARDCOPYIV;
    input[8*20:1] device;
    reg is_hardcopyiv;
begin
    if ((device == "HardCopy IV") || (device == "HARDCOPY IV") || (device == "hardcopy iv") || (device == "HardCopyIV") || (device == "HARDCOPYIV") || (device == "hardcopyiv") || (device == "HardCopy IV (GX)") || (device == "HARDCOPY IV (GX)") || (device == "hardcopy iv (gx)") || (device == "HardCopy IV (E)") || (device == "HARDCOPY IV (E)") || (device == "hardcopy iv (e)") || (device == "HardCopyIV(GX)") || (device == "HARDCOPYIV(GX)") || (device == "hardcopyiv(gx)") || (device == "HardCopyIV(E)") || (device == "HARDCOPYIV(E)") || (device == "hardcopyiv(e)") || (device == "HCXIV") || (device == "hcxiv") || (device == "HardCopy IV (GX/E)") || (device == "HARDCOPY IV (GX/E)") || (device == "hardcopy iv (gx/e)") || (device == "HardCopy IV (E/GX)") || (device == "HARDCOPY IV (E/GX)") || (device == "hardcopy iv (e/gx)") || (device == "HardCopyIV(GX/E)") || (device == "HARDCOPYIV(GX/E)") || (device == "hardcopyiv(gx/e)") || (device == "HardCopyIV(E/GX)") || (device == "HARDCOPYIV(E/GX)") || (device == "hardcopyiv(e/gx)"))
        is_hardcopyiv = 1;
    else
        is_hardcopyiv = 0;

    IS_FAMILY_HARDCOPYIV  = is_hardcopyiv;
end
endfunction //IS_FAMILY_HARDCOPYIV

function IS_FAMILY_MAXII;
    input[8*20:1] device;
    reg is_maxii;
begin
    if ((device == "MAX II") || (device == "max ii") || (device == "MAXII") || (device == "maxii") || (device == "Tsunami") || (device == "TSUNAMI") || (device == "tsunami"))
        is_maxii = 1;
    else
        is_maxii = 0;

    IS_FAMILY_MAXII  = is_maxii;
end
endfunction //IS_FAMILY_MAXII

function IS_FAMILY_MAXV;
    input[8*20:1] device;
    reg is_maxv;
begin
    if ((device == "MAX V") || (device == "max v") || (device == "MAXV") || (device == "maxv") || (device == "Jade") || (device == "JADE") || (device == "jade"))
        is_maxv = 1;
    else
        is_maxv = 0;

    IS_FAMILY_MAXV  = is_maxv;
end
endfunction //IS_FAMILY_MAXV

function IS_FAMILY_STRATIXGX;
    input[8*20:1] device;
    reg is_stratixgx;
begin
    if ((device == "Stratix GX") || (device == "STRATIX GX") || (device == "stratix gx") || (device == "Stratix-GX") || (device == "STRATIX-GX") || (device == "stratix-gx") || (device == "StratixGX") || (device == "STRATIXGX") || (device == "stratixgx") || (device == "Aurora") || (device == "AURORA") || (device == "aurora"))
        is_stratixgx = 1;
    else
        is_stratixgx = 0;

    IS_FAMILY_STRATIXGX  = is_stratixgx;
end
endfunction //IS_FAMILY_STRATIXGX

function IS_FAMILY_STRATIXIIGX;
    input[8*20:1] device;
    reg is_stratixiigx;
begin
    if ((device == "Stratix II GX") || (device == "STRATIX II GX") || (device == "stratix ii gx") || (device == "StratixIIGX") || (device == "STRATIXIIGX") || (device == "stratixiigx"))
        is_stratixiigx = 1;
    else
        is_stratixiigx = 0;

    IS_FAMILY_STRATIXIIGX  = is_stratixiigx;
end
endfunction //IS_FAMILY_STRATIXIIGX

function IS_FAMILY_STRATIXII;
    input[8*20:1] device;
    reg is_stratixii;
begin
    if ((device == "Stratix II") || (device == "STRATIX II") || (device == "stratix ii") || (device == "StratixII") || (device == "STRATIXII") || (device == "stratixii") || (device == "Armstrong") || (device == "ARMSTRONG") || (device == "armstrong"))
        is_stratixii = 1;
    else
        is_stratixii = 0;

    IS_FAMILY_STRATIXII  = is_stratixii;
end
endfunction //IS_FAMILY_STRATIXII

function IS_FAMILY_STRATIXIII;
    input[8*20:1] device;
    reg is_stratixiii;
begin
    if ((device == "Stratix III") || (device == "STRATIX III") || (device == "stratix iii") || (device == "StratixIII") || (device == "STRATIXIII") || (device == "stratixiii") || (device == "Titan") || (device == "TITAN") || (device == "titan") || (device == "SIII") || (device == "siii"))
        is_stratixiii = 1;
    else
        is_stratixiii = 0;

    IS_FAMILY_STRATIXIII  = is_stratixiii;
end
endfunction //IS_FAMILY_STRATIXIII

function IS_FAMILY_STRATIXIV;
    input[8*20:1] device;
    reg is_stratixiv;
begin
    if ((device == "Stratix IV") || (device == "STRATIX IV") || (device == "stratix iv") || (device == "TGX") || (device == "tgx") || (device == "StratixIV") || (device == "STRATIXIV") || (device == "stratixiv") || (device == "Stratix IV (GT)") || (device == "STRATIX IV (GT)") || (device == "stratix iv (gt)") || (device == "Stratix IV (GX)") || (device == "STRATIX IV (GX)") || (device == "stratix iv (gx)") || (device == "Stratix IV (E)") || (device == "STRATIX IV (E)") || (device == "stratix iv (e)") || (device == "StratixIV(GT)") || (device == "STRATIXIV(GT)") || (device == "stratixiv(gt)") || (device == "StratixIV(GX)") || (device == "STRATIXIV(GX)") || (device == "stratixiv(gx)") || (device == "StratixIV(E)") || (device == "STRATIXIV(E)") || (device == "stratixiv(e)") || (device == "StratixIIIGX") || (device == "STRATIXIIIGX") || (device == "stratixiiigx") || (device == "Stratix IV (GT/GX/E)") || (device == "STRATIX IV (GT/GX/E)") || (device == "stratix iv (gt/gx/e)") || (device == "Stratix IV (GT/E/GX)") || (device == "STRATIX IV (GT/E/GX)") || (device == "stratix iv (gt/e/gx)") || (device == "Stratix IV (E/GT/GX)") || (device == "STRATIX IV (E/GT/GX)") || (device == "stratix iv (e/gt/gx)") || (device == "Stratix IV (E/GX/GT)") || (device == "STRATIX IV (E/GX/GT)") || (device == "stratix iv (e/gx/gt)") || (device == "StratixIV(GT/GX/E)") || (device == "STRATIXIV(GT/GX/E)") || (device == "stratixiv(gt/gx/e)") || (device == "StratixIV(GT/E/GX)") || (device == "STRATIXIV(GT/E/GX)") || (device == "stratixiv(gt/e/gx)") || (device == "StratixIV(E/GX/GT)") || (device == "STRATIXIV(E/GX/GT)") || (device == "stratixiv(e/gx/gt)") || (device == "StratixIV(E/GT/GX)") || (device == "STRATIXIV(E/GT/GX)") || (device == "stratixiv(e/gt/gx)") || (device == "Stratix IV (GX/E)") || (device == "STRATIX IV (GX/E)") || (device == "stratix iv (gx/e)") || (device == "StratixIV(GX/E)") || (device == "STRATIXIV(GX/E)") || (device == "stratixiv(gx/e)"))
        is_stratixiv = 1;
    else
        is_stratixiv = 0;

    IS_FAMILY_STRATIXIV  = is_stratixiv;
end
endfunction //IS_FAMILY_STRATIXIV

function IS_FAMILY_STRATIXV;
    input[8*20:1] device;
    reg is_stratixv;
begin
    if ((device == "Stratix V") || (device == "STRATIX V") || (device == "stratix v") || (device == "StratixV") || (device == "STRATIXV") || (device == "stratixv") || (device == "Stratix V (GS)") || (device == "STRATIX V (GS)") || (device == "stratix v (gs)") || (device == "StratixV(GS)") || (device == "STRATIXV(GS)") || (device == "stratixv(gs)") || (device == "Stratix V (GT)") || (device == "STRATIX V (GT)") || (device == "stratix v (gt)") || (device == "StratixV(GT)") || (device == "STRATIXV(GT)") || (device == "stratixv(gt)") || (device == "Stratix V (GX)") || (device == "STRATIX V (GX)") || (device == "stratix v (gx)") || (device == "StratixV(GX)") || (device == "STRATIXV(GX)") || (device == "stratixv(gx)") || (device == "Stratix V (GS/GX)") || (device == "STRATIX V (GS/GX)") || (device == "stratix v (gs/gx)") || (device == "StratixV(GS/GX)") || (device == "STRATIXV(GS/GX)") || (device == "stratixv(gs/gx)") || (device == "Stratix V (GS/GT)") || (device == "STRATIX V (GS/GT)") || (device == "stratix v (gs/gt)") || (device == "StratixV(GS/GT)") || (device == "STRATIXV(GS/GT)") || (device == "stratixv(gs/gt)") || (device == "Stratix V (GT/GX)") || (device == "STRATIX V (GT/GX)") || (device == "stratix v (gt/gx)") || (device == "StratixV(GT/GX)") || (device == "STRATIXV(GT/GX)") || (device == "stratixv(gt/gx)") || (device == "Stratix V (GX/GS)") || (device == "STRATIX V (GX/GS)") || (device == "stratix v (gx/gs)") || (device == "StratixV(GX/GS)") || (device == "STRATIXV(GX/GS)") || (device == "stratixv(gx/gs)") || (device == "Stratix V (GT/GS)") || (device == "STRATIX V (GT/GS)") || (device == "stratix v (gt/gs)") || (device == "StratixV(GT/GS)") || (device == "STRATIXV(GT/GS)") || (device == "stratixv(gt/gs)") || (device == "Stratix V (GX/GT)") || (device == "STRATIX V (GX/GT)") || (device == "stratix v (gx/gt)") || (device == "StratixV(GX/GT)") || (device == "STRATIXV(GX/GT)") || (device == "stratixv(gx/gt)") || (device == "Stratix V (GS/GT/GX)") || (device == "STRATIX V (GS/GT/GX)") || (device == "stratix v (gs/gt/gx)") || (device == "Stratix V (GS/GX/GT)") || (device == "STRATIX V (GS/GX/GT)") || (device == "stratix v (gs/gx/gt)") || (device == "Stratix V (GT/GS/GX)") || (device == "STRATIX V (GT/GS/GX)") || (device == "stratix v (gt/gs/gx)") || (device == "Stratix V (GT/GX/GS)") || (device == "STRATIX V (GT/GX/GS)") || (device == "stratix v (gt/gx/gs)") || (device == "Stratix V (GX/GS/GT)") || (device == "STRATIX V (GX/GS/GT)") || (device == "stratix v (gx/gs/gt)") || (device == "Stratix V (GX/GT/GS)") || (device == "STRATIX V (GX/GT/GS)") || (device == "stratix v (gx/gt/gs)") || (device == "StratixV(GS/GT/GX)") || (device == "STRATIXV(GS/GT/GX)") || (device == "stratixv(gs/gt/gx)") || (device == "StratixV(GS/GX/GT)") || (device == "STRATIXV(GS/GX/GT)") || (device == "stratixv(gs/gx/gt)") || (device == "StratixV(GT/GS/GX)") || (device == "STRATIXV(GT/GS/GX)") || (device == "stratixv(gt/gs/gx)") || (device == "StratixV(GT/GX/GS)") || (device == "STRATIXV(GT/GX/GS)") || (device == "stratixv(gt/gx/gs)") || (device == "StratixV(GX/GS/GT)") || (device == "STRATIXV(GX/GS/GT)") || (device == "stratixv(gx/gs/gt)") || (device == "StratixV(GX/GT/GS)") || (device == "STRATIXV(GX/GT/GS)") || (device == "stratixv(gx/gt/gs)") || (device == "Stratix V (GS/GT/GX/E)") || (device == "STRATIX V (GS/GT/GX/E)") || (device == "stratix v (gs/gt/gx/e)") || (device == "StratixV(GS/GT/GX/E)") || (device == "STRATIXV(GS/GT/GX/E)") || (device == "stratixv(gs/gt/gx/e)") || (device == "Stratix V (E)") || (device == "STRATIX V (E)") || (device == "stratix v (e)") || (device == "StratixV(E)") || (device == "STRATIXV(E)") || (device == "stratixv(e)"))
        is_stratixv = 1;
    else
        is_stratixv = 0;

    IS_FAMILY_STRATIXV  = is_stratixv;
end
endfunction //IS_FAMILY_STRATIXV

function IS_FAMILY_STRATIXVI;
    input[8*20:1] device;
    reg is_stratixvi;
begin
    if ((device == "Stratix VI") || (device == "STRATIX VI") || (device == "stratix vi") || (device == "StratixVI") || (device == "STRATIXVI") || (device == "stratixvi") || (device == "Night Fury") || (device == "NIGHT FURY") || (device == "night fury") || (device == "nightfury") || (device == "NIGHTFURY") || (device == "Stratix VI (GS/GX)") || (device == "STRATIX VI (GS/GX)") || (device == "stratix vi (gs/gx)") || (device == "StratixVI(GS/GX)") || (device == "STRATIXVI(GS/GX)") || (device == "stratixvi(gs/gx)") || (device == "Stratix VI (GS)") || (device == "STRATIX VI (GS)") || (device == "stratix vi (gs)") || (device == "StratixVI(GS)") || (device == "STRATIXVI(GS)") || (device == "stratixvi(gs)") || (device == "Stratix VI (GX)") || (device == "STRATIX VI (GX)") || (device == "stratix vi (gx)") || (device == "StratixVI(GX)") || (device == "STRATIXVI(GX)") || (device == "stratixvi(gx)"))
        is_stratixvi = 1;
    else
        is_stratixvi = 0;

    IS_FAMILY_STRATIXVI  = is_stratixvi;
end
endfunction //IS_FAMILY_STRATIXVI

function IS_FAMILY_STRATIX;
    input[8*20:1] device;
    reg is_stratix;
begin
    if ((device == "Stratix") || (device == "STRATIX") || (device == "stratix") || (device == "Yeager") || (device == "YEAGER") || (device == "yeager"))
        is_stratix = 1;
    else
        is_stratix = 0;

    IS_FAMILY_STRATIX  = is_stratix;
end
endfunction //IS_FAMILY_STRATIX

function FEATURE_FAMILY_STRATIXGX;
    input[8*20:1] device;
    reg var_family_stratixgx;
begin
    if (IS_FAMILY_STRATIXGX(device) )
        var_family_stratixgx = 1;
    else
        var_family_stratixgx = 0;

    FEATURE_FAMILY_STRATIXGX  = var_family_stratixgx;
end
endfunction //FEATURE_FAMILY_STRATIXGX

function FEATURE_FAMILY_CYCLONE;
    input[8*20:1] device;
    reg var_family_cyclone;
begin
    if (IS_FAMILY_CYCLONE(device) )
        var_family_cyclone = 1;
    else
        var_family_cyclone = 0;

    FEATURE_FAMILY_CYCLONE  = var_family_cyclone;
end
endfunction //FEATURE_FAMILY_CYCLONE

function FEATURE_FAMILY_STRATIXIIGX;
    input[8*20:1] device;
    reg var_family_stratixiigx;
begin
    if (IS_FAMILY_STRATIXIIGX(device) || IS_FAMILY_ARRIAGX(device) )
        var_family_stratixiigx = 1;
    else
        var_family_stratixiigx = 0;

    FEATURE_FAMILY_STRATIXIIGX  = var_family_stratixiigx;
end
endfunction //FEATURE_FAMILY_STRATIXIIGX

function FEATURE_FAMILY_STRATIXIII;
    input[8*20:1] device;
    reg var_family_stratixiii;
begin
    if (IS_FAMILY_STRATIXIII(device) || FEATURE_FAMILY_STRATIXIV(device) || FEATURE_FAMILY_HARDCOPYIII(device) )
        var_family_stratixiii = 1;
    else
        var_family_stratixiii = 0;

    FEATURE_FAMILY_STRATIXIII  = var_family_stratixiii;
end
endfunction //FEATURE_FAMILY_STRATIXIII

function FEATURE_FAMILY_ARRIAVGZ;
    input[8*20:1] device;
    reg var_family_arriavgz;
begin
    if (IS_FAMILY_ARRIAVGZ(device) )
        var_family_arriavgz = 1;
    else
        var_family_arriavgz = 0;

    FEATURE_FAMILY_ARRIAVGZ  = var_family_arriavgz;
end
endfunction //FEATURE_FAMILY_ARRIAVGZ

function FEATURE_FAMILY_ARRIAVI;
    input[8*20:1] device;
    reg var_family_arriavi;
begin
    if (IS_FAMILY_ARRIAVI(device) )
        var_family_arriavi = 1;
    else
        var_family_arriavi = 0;

    FEATURE_FAMILY_ARRIAVI  = var_family_arriavi;
end
endfunction //FEATURE_FAMILY_ARRIAVI

function FEATURE_FAMILY_STRATIXV;
    input[8*20:1] device;
    reg var_family_stratixv;
begin
    if (IS_FAMILY_STRATIXV(device) || FEATURE_FAMILY_ARRIAVGZ(device) )
        var_family_stratixv = 1;
    else
        var_family_stratixv = 0;

    FEATURE_FAMILY_STRATIXV  = var_family_stratixv;
end
endfunction //FEATURE_FAMILY_STRATIXV

function FEATURE_FAMILY_STRATIXVI;
    input[8*20:1] device;
    reg var_family_stratixvi;
begin
    if (IS_FAMILY_STRATIXVI(device) || IS_FAMILY_STRATIXVI(device) || FEATURE_FAMILY_ARRIAVI(device) )
        var_family_stratixvi = 1;
    else
        var_family_stratixvi = 0;

    FEATURE_FAMILY_STRATIXVI  = var_family_stratixvi;
end
endfunction //FEATURE_FAMILY_STRATIXVI

function FEATURE_FAMILY_STRATIXII;
    input[8*20:1] device;
    reg var_family_stratixii;
begin
    if (IS_FAMILY_STRATIXII(device) || IS_FAMILY_HARDCOPYII(device) || FEATURE_FAMILY_STRATIXIIGX(device) || FEATURE_FAMILY_STRATIXIII(device) )
        var_family_stratixii = 1;
    else
        var_family_stratixii = 0;

    FEATURE_FAMILY_STRATIXII  = var_family_stratixii;
end
endfunction //FEATURE_FAMILY_STRATIXII

function FEATURE_FAMILY_CYCLONEIVGX;
    input[8*20:1] device;
    reg var_family_cycloneivgx;
begin
    if (IS_FAMILY_CYCLONEIVGX(device) || IS_FAMILY_CYCLONEIVGX(device) )
        var_family_cycloneivgx = 1;
    else
        var_family_cycloneivgx = 0;

    FEATURE_FAMILY_CYCLONEIVGX  = var_family_cycloneivgx;
end
endfunction //FEATURE_FAMILY_CYCLONEIVGX

function FEATURE_FAMILY_CYCLONEIVE;
    input[8*20:1] device;
    reg var_family_cycloneive;
begin
    if (IS_FAMILY_CYCLONEIVE(device) )
        var_family_cycloneive = 1;
    else
        var_family_cycloneive = 0;

    FEATURE_FAMILY_CYCLONEIVE  = var_family_cycloneive;
end
endfunction //FEATURE_FAMILY_CYCLONEIVE

function FEATURE_FAMILY_CYCLONEIII;
    input[8*20:1] device;
    reg var_family_cycloneiii;
begin
    if (IS_FAMILY_CYCLONEIII(device) || IS_FAMILY_CYCLONEIIILS(device) || FEATURE_FAMILY_CYCLONEIVGX(device) || FEATURE_FAMILY_CYCLONEIVE(device) )
        var_family_cycloneiii = 1;
    else
        var_family_cycloneiii = 0;

    FEATURE_FAMILY_CYCLONEIII  = var_family_cycloneiii;
end
endfunction //FEATURE_FAMILY_CYCLONEIII

function FEATURE_FAMILY_STRATIX_HC;
    input[8*20:1] device;
    reg var_family_stratix_hc;
begin
    if ((device == "StratixHC") )
        var_family_stratix_hc = 1;
    else
        var_family_stratix_hc = 0;

    FEATURE_FAMILY_STRATIX_HC  = var_family_stratix_hc;
end
endfunction //FEATURE_FAMILY_STRATIX_HC

function FEATURE_FAMILY_STRATIX;
    input[8*20:1] device;
    reg var_family_stratix;
begin
    if (IS_FAMILY_STRATIX(device) || FEATURE_FAMILY_STRATIX_HC(device) || FEATURE_FAMILY_STRATIXGX(device) || FEATURE_FAMILY_CYCLONE(device) || FEATURE_FAMILY_STRATIXII(device) || FEATURE_FAMILY_MAXII(device) || FEATURE_FAMILY_CYCLONEII(device) )
        var_family_stratix = 1;
    else
        var_family_stratix = 0;

    FEATURE_FAMILY_STRATIX  = var_family_stratix;
end
endfunction //FEATURE_FAMILY_STRATIX

function FEATURE_FAMILY_MAXII;
    input[8*20:1] device;
    reg var_family_maxii;
begin
    if (IS_FAMILY_MAXII(device) || FEATURE_FAMILY_MAXV(device) )
        var_family_maxii = 1;
    else
        var_family_maxii = 0;

    FEATURE_FAMILY_MAXII  = var_family_maxii;
end
endfunction //FEATURE_FAMILY_MAXII

function FEATURE_FAMILY_MAXV;
    input[8*20:1] device;
    reg var_family_maxv;
begin
    if (IS_FAMILY_MAXV(device) )
        var_family_maxv = 1;
    else
        var_family_maxv = 0;

    FEATURE_FAMILY_MAXV  = var_family_maxv;
end
endfunction //FEATURE_FAMILY_MAXV

function FEATURE_FAMILY_CYCLONEII;
    input[8*20:1] device;
    reg var_family_cycloneii;
begin
    if (IS_FAMILY_CYCLONEII(device) || FEATURE_FAMILY_CYCLONEIII(device) )
        var_family_cycloneii = 1;
    else
        var_family_cycloneii = 0;

    FEATURE_FAMILY_CYCLONEII  = var_family_cycloneii;
end
endfunction //FEATURE_FAMILY_CYCLONEII

function FEATURE_FAMILY_STRATIXIV;
    input[8*20:1] device;
    reg var_family_stratixiv;
begin
    if (IS_FAMILY_STRATIXIV(device) || IS_FAMILY_ARRIAIIGX(device) || FEATURE_FAMILY_HARDCOPYIV(device) || FEATURE_FAMILY_STRATIXV(device) || FEATURE_FAMILY_ARRIAV(device) || FEATURE_FAMILY_ARRIAIIGZ(device) || FEATURE_FAMILY_STRATIXVI(device) )
        var_family_stratixiv = 1;
    else
        var_family_stratixiv = 0;

    FEATURE_FAMILY_STRATIXIV  = var_family_stratixiv;
end
endfunction //FEATURE_FAMILY_STRATIXIV

function FEATURE_FAMILY_ARRIAIIGZ;
    input[8*20:1] device;
    reg var_family_arriaiigz;
begin
    if (IS_FAMILY_ARRIAIIGZ(device) )
        var_family_arriaiigz = 1;
    else
        var_family_arriaiigz = 0;

    FEATURE_FAMILY_ARRIAIIGZ  = var_family_arriaiigz;
end
endfunction //FEATURE_FAMILY_ARRIAIIGZ

function FEATURE_FAMILY_ARRIAIIGX;
    input[8*20:1] device;
    reg var_family_arriaiigx;
begin
    if (IS_FAMILY_ARRIAIIGX(device) )
        var_family_arriaiigx = 1;
    else
        var_family_arriaiigx = 0;

    FEATURE_FAMILY_ARRIAIIGX  = var_family_arriaiigx;
end
endfunction //FEATURE_FAMILY_ARRIAIIGX

function FEATURE_FAMILY_HARDCOPYIII;
    input[8*20:1] device;
    reg var_family_hardcopyiii;
begin
    if (IS_FAMILY_HARDCOPYIII(device) || IS_FAMILY_HARDCOPYIII(device) )
        var_family_hardcopyiii = 1;
    else
        var_family_hardcopyiii = 0;

    FEATURE_FAMILY_HARDCOPYIII  = var_family_hardcopyiii;
end
endfunction //FEATURE_FAMILY_HARDCOPYIII

function FEATURE_FAMILY_HARDCOPYIV;
    input[8*20:1] device;
    reg var_family_hardcopyiv;
begin
    if (IS_FAMILY_HARDCOPYIV(device) || IS_FAMILY_HARDCOPYIV(device) )
        var_family_hardcopyiv = 1;
    else
        var_family_hardcopyiv = 0;

    FEATURE_FAMILY_HARDCOPYIV  = var_family_hardcopyiv;
end
endfunction //FEATURE_FAMILY_HARDCOPYIV

function FEATURE_FAMILY_CYCLONEV;
    input[8*20:1] device;
    reg var_family_cyclonev;
begin
    if (IS_FAMILY_CYCLONEV(device) )
        var_family_cyclonev = 1;
    else
        var_family_cyclonev = 0;

    FEATURE_FAMILY_CYCLONEV  = var_family_cyclonev;
end
endfunction //FEATURE_FAMILY_CYCLONEV

function FEATURE_FAMILY_ARRIAV;
    input[8*20:1] device;
    reg var_family_arriav;
begin
    if (IS_FAMILY_ARRIAV(device) || FEATURE_FAMILY_CYCLONEV(device) )
        var_family_arriav = 1;
    else
        var_family_arriav = 0;

    FEATURE_FAMILY_ARRIAV  = var_family_arriav;
end
endfunction //FEATURE_FAMILY_ARRIAV

function FEATURE_FAMILY_BASE_STRATIXII;
    input[8*20:1] device;
    reg var_family_base_stratixii;
begin
    if (IS_FAMILY_STRATIXII(device) || IS_FAMILY_HARDCOPYII(device) || FEATURE_FAMILY_STRATIXIIGX(device) )
        var_family_base_stratixii = 1;
    else
        var_family_base_stratixii = 0;

    FEATURE_FAMILY_BASE_STRATIXII  = var_family_base_stratixii;
end
endfunction //FEATURE_FAMILY_BASE_STRATIXII

function FEATURE_FAMILY_BASE_STRATIX;
    input[8*20:1] device;
    reg var_family_base_stratix;
begin
    if (IS_FAMILY_STRATIX(device) || IS_FAMILY_STRATIXGX(device) )
        var_family_base_stratix = 1;
    else
        var_family_base_stratix = 0;

    FEATURE_FAMILY_BASE_STRATIX  = var_family_base_stratix;
end
endfunction //FEATURE_FAMILY_BASE_STRATIX

function FEATURE_FAMILY_BASE_CYCLONEII;
    input[8*20:1] device;
    reg var_family_base_cycloneii;
begin
    if (IS_FAMILY_CYCLONEII(device) )
        var_family_base_cycloneii = 1;
    else
        var_family_base_cycloneii = 0;

    FEATURE_FAMILY_BASE_CYCLONEII  = var_family_base_cycloneii;
end
endfunction //FEATURE_FAMILY_BASE_CYCLONEII

function FEATURE_FAMILY_BASE_CYCLONE;
    input[8*20:1] device;
    reg var_family_base_cyclone;
begin
    if (IS_FAMILY_CYCLONE(device) )
        var_family_base_cyclone = 1;
    else
        var_family_base_cyclone = 0;

    FEATURE_FAMILY_BASE_CYCLONE  = var_family_base_cyclone;
end
endfunction //FEATURE_FAMILY_BASE_CYCLONE

function FEATURE_FAMILY_HAS_ALTERA_MULT_ADD_FLOW;
    input[8*20:1] device;
    reg var_family_has_altera_mult_add_flow;
begin
    if (FEATURE_FAMILY_STRATIXV(device) || FEATURE_FAMILY_ARRIAV(device) || FEATURE_FAMILY_CYCLONEV(device) || FEATURE_FAMILY_STRATIXVI(device) )
        var_family_has_altera_mult_add_flow = 1;
    else
        var_family_has_altera_mult_add_flow = 0;

    FEATURE_FAMILY_HAS_ALTERA_MULT_ADD_FLOW  = var_family_has_altera_mult_add_flow;
end
endfunction //FEATURE_FAMILY_HAS_ALTERA_MULT_ADD_FLOW

function FEATURE_FAMILY_IS_ALTMULT_ADD_EOL;
    input[8*20:1] device;
    reg var_family_is_altmult_add_eol;
begin
    if (FEATURE_FAMILY_STRATIXVI(device) )
        var_family_is_altmult_add_eol = 1;
    else
        var_family_is_altmult_add_eol = 0;

    FEATURE_FAMILY_IS_ALTMULT_ADD_EOL  = var_family_is_altmult_add_eol;
end
endfunction //FEATURE_FAMILY_IS_ALTMULT_ADD_EOL

function FEATURE_FAMILY_HAS_STRATIXII_STYLE_RAM;
    input[8*20:1] device;
    reg var_family_has_stratixii_style_ram;
begin
    if (FEATURE_FAMILY_STRATIXII(device) || FEATURE_FAMILY_CYCLONEII(device) )
        var_family_has_stratixii_style_ram = 1;
    else
        var_family_has_stratixii_style_ram = 0;

    FEATURE_FAMILY_HAS_STRATIXII_STYLE_RAM  = var_family_has_stratixii_style_ram;
end
endfunction //FEATURE_FAMILY_HAS_STRATIXII_STYLE_RAM

function FEATURE_FAMILY_HAS_STRATIXIII_STYLE_RAM;
    input[8*20:1] device;
    reg var_family_has_stratixiii_style_ram;
begin
    if (FEATURE_FAMILY_STRATIXIII(device) || FEATURE_FAMILY_CYCLONEIII(device) )
        var_family_has_stratixiii_style_ram = 1;
    else
        var_family_has_stratixiii_style_ram = 0;

    FEATURE_FAMILY_HAS_STRATIXIII_STYLE_RAM  = var_family_has_stratixiii_style_ram;
end
endfunction //FEATURE_FAMILY_HAS_STRATIXIII_STYLE_RAM

function FEATURE_FAMILY_HAS_STRATIX_STYLE_PLL;
    input[8*20:1] device;
    reg var_family_has_stratix_style_pll;
begin
    if (FEATURE_FAMILY_CYCLONE(device) || FEATURE_FAMILY_STRATIX_HC(device) || IS_FAMILY_STRATIX(device) || FEATURE_FAMILY_STRATIXGX(device) )
        var_family_has_stratix_style_pll = 1;
    else
        var_family_has_stratix_style_pll = 0;

    FEATURE_FAMILY_HAS_STRATIX_STYLE_PLL  = var_family_has_stratix_style_pll;
end
endfunction //FEATURE_FAMILY_HAS_STRATIX_STYLE_PLL

function FEATURE_FAMILY_HAS_STRATIXII_STYLE_PLL;
    input[8*20:1] device;
    reg var_family_has_stratixii_style_pll;
begin
    if (FEATURE_FAMILY_STRATIXII(device) && ! FEATURE_FAMILY_STRATIXIII(device) || FEATURE_FAMILY_CYCLONEII(device) && ! FEATURE_FAMILY_CYCLONEIII(device) )
        var_family_has_stratixii_style_pll = 1;
    else
        var_family_has_stratixii_style_pll = 0;

    FEATURE_FAMILY_HAS_STRATIXII_STYLE_PLL  = var_family_has_stratixii_style_pll;
end
endfunction //FEATURE_FAMILY_HAS_STRATIXII_STYLE_PLL

function FEATURE_FAMILY_HAS_INVERTED_OUTPUT_DDIO;
    input[8*20:1] device;
    reg var_family_has_inverted_output_ddio;
begin
    if (FEATURE_FAMILY_CYCLONEII(device) )
        var_family_has_inverted_output_ddio = 1;
    else
        var_family_has_inverted_output_ddio = 0;

    FEATURE_FAMILY_HAS_INVERTED_OUTPUT_DDIO  = var_family_has_inverted_output_ddio;
end
endfunction //FEATURE_FAMILY_HAS_INVERTED_OUTPUT_DDIO

function IS_VALID_FAMILY;
    input[8*20:1] device;
    reg is_valid;
begin
    if (((device == "Arria GX") || (device == "ARRIA GX") || (device == "arria gx") || (device == "ArriaGX") || (device == "ARRIAGX") || (device == "arriagx") || (device == "Stratix II GX Lite") || (device == "STRATIX II GX LITE") || (device == "stratix ii gx lite") || (device == "StratixIIGXLite") || (device == "STRATIXIIGXLITE") || (device == "stratixiigxlite"))
    || ((device == "Arria II GX") || (device == "ARRIA II GX") || (device == "arria ii gx") || (device == "ArriaIIGX") || (device == "ARRIAIIGX") || (device == "arriaiigx") || (device == "Arria IIGX") || (device == "ARRIA IIGX") || (device == "arria iigx") || (device == "ArriaII GX") || (device == "ARRIAII GX") || (device == "arriaii gx") || (device == "Arria II") || (device == "ARRIA II") || (device == "arria ii") || (device == "ArriaII") || (device == "ARRIAII") || (device == "arriaii") || (device == "Arria II (GX/E)") || (device == "ARRIA II (GX/E)") || (device == "arria ii (gx/e)") || (device == "ArriaII(GX/E)") || (device == "ARRIAII(GX/E)") || (device == "arriaii(gx/e)") || (device == "PIRANHA") || (device == "piranha"))
    || ((device == "Arria II GZ") || (device == "ARRIA II GZ") || (device == "arria ii gz") || (device == "ArriaII GZ") || (device == "ARRIAII GZ") || (device == "arriaii gz") || (device == "Arria IIGZ") || (device == "ARRIA IIGZ") || (device == "arria iigz") || (device == "ArriaIIGZ") || (device == "ARRIAIIGZ") || (device == "arriaiigz"))
    || ((device == "Arria V GZ") || (device == "ARRIA V GZ") || (device == "arria v gz") || (device == "ArriaVGZ") || (device == "ARRIAVGZ") || (device == "arriavgz"))
    || ((device == "Arria V") || (device == "ARRIA V") || (device == "arria v") || (device == "Arria V (GT/GX)") || (device == "ARRIA V (GT/GX)") || (device == "arria v (gt/gx)") || (device == "ArriaV(GT/GX)") || (device == "ARRIAV(GT/GX)") || (device == "arriav(gt/gx)") || (device == "ArriaV") || (device == "ARRIAV") || (device == "arriav") || (device == "Arria V (GT/GX/ST/SX)") || (device == "ARRIA V (GT/GX/ST/SX)") || (device == "arria v (gt/gx/st/sx)") || (device == "ArriaV(GT/GX/ST/SX)") || (device == "ARRIAV(GT/GX/ST/SX)") || (device == "arriav(gt/gx/st/sx)") || (device == "Arria V (GT)") || (device == "ARRIA V (GT)") || (device == "arria v (gt)") || (device == "ArriaV(GT)") || (device == "ARRIAV(GT)") || (device == "arriav(gt)") || (device == "Arria V (GX)") || (device == "ARRIA V (GX)") || (device == "arria v (gx)") || (device == "ArriaV(GX)") || (device == "ARRIAV(GX)") || (device == "arriav(gx)") || (device == "Arria V (ST)") || (device == "ARRIA V (ST)") || (device == "arria v (st)") || (device == "ArriaV(ST)") || (device == "ARRIAV(ST)") || (device == "arriav(st)") || (device == "Arria V (SX)") || (device == "ARRIA V (SX)") || (device == "arria v (sx)") || (device == "ArriaV(SX)") || (device == "ARRIAV(SX)") || (device == "arriav(sx)"))
    || ((device == "Arria VI") || (device == "ARRIA VI") || (device == "arria vi") || (device == "ArriaVI") || (device == "ARRIAVI") || (device == "arriavi"))
    || ((device == "BS") || (device == "bs"))
    || ((device == "Cyclone II") || (device == "CYCLONE II") || (device == "cyclone ii") || (device == "Cycloneii") || (device == "CYCLONEII") || (device == "cycloneii") || (device == "Magellan") || (device == "MAGELLAN") || (device == "magellan") || (device == "CycloneII") || (device == "CYCLONEII") || (device == "cycloneii"))
    || ((device == "Cyclone III LS") || (device == "CYCLONE III LS") || (device == "cyclone iii ls") || (device == "CycloneIIILS") || (device == "CYCLONEIIILS") || (device == "cycloneiiils") || (device == "Cyclone III LPS") || (device == "CYCLONE III LPS") || (device == "cyclone iii lps") || (device == "Cyclone LPS") || (device == "CYCLONE LPS") || (device == "cyclone lps") || (device == "CycloneLPS") || (device == "CYCLONELPS") || (device == "cyclonelps") || (device == "Tarpon") || (device == "TARPON") || (device == "tarpon") || (device == "Cyclone IIIE") || (device == "CYCLONE IIIE") || (device == "cyclone iiie"))
    || ((device == "Cyclone III") || (device == "CYCLONE III") || (device == "cyclone iii") || (device == "CycloneIII") || (device == "CYCLONEIII") || (device == "cycloneiii") || (device == "Barracuda") || (device == "BARRACUDA") || (device == "barracuda") || (device == "Cuda") || (device == "CUDA") || (device == "cuda") || (device == "CIII") || (device == "ciii"))
    || ((device == "Cyclone IV E") || (device == "CYCLONE IV E") || (device == "cyclone iv e") || (device == "CycloneIV E") || (device == "CYCLONEIV E") || (device == "cycloneiv e") || (device == "Cyclone IVE") || (device == "CYCLONE IVE") || (device == "cyclone ive") || (device == "CycloneIVE") || (device == "CYCLONEIVE") || (device == "cycloneive"))
    || ((device == "Cyclone IV GX") || (device == "CYCLONE IV GX") || (device == "cyclone iv gx") || (device == "Cyclone IVGX") || (device == "CYCLONE IVGX") || (device == "cyclone ivgx") || (device == "CycloneIV GX") || (device == "CYCLONEIV GX") || (device == "cycloneiv gx") || (device == "CycloneIVGX") || (device == "CYCLONEIVGX") || (device == "cycloneivgx") || (device == "Cyclone IV") || (device == "CYCLONE IV") || (device == "cyclone iv") || (device == "CycloneIV") || (device == "CYCLONEIV") || (device == "cycloneiv") || (device == "Cyclone IV (GX)") || (device == "CYCLONE IV (GX)") || (device == "cyclone iv (gx)") || (device == "CycloneIV(GX)") || (device == "CYCLONEIV(GX)") || (device == "cycloneiv(gx)") || (device == "Cyclone III GX") || (device == "CYCLONE III GX") || (device == "cyclone iii gx") || (device == "CycloneIII GX") || (device == "CYCLONEIII GX") || (device == "cycloneiii gx") || (device == "Cyclone IIIGX") || (device == "CYCLONE IIIGX") || (device == "cyclone iiigx") || (device == "CycloneIIIGX") || (device == "CYCLONEIIIGX") || (device == "cycloneiiigx") || (device == "Cyclone III GL") || (device == "CYCLONE III GL") || (device == "cyclone iii gl") || (device == "CycloneIII GL") || (device == "CYCLONEIII GL") || (device == "cycloneiii gl") || (device == "Cyclone IIIGL") || (device == "CYCLONE IIIGL") || (device == "cyclone iiigl") || (device == "CycloneIIIGL") || (device == "CYCLONEIIIGL") || (device == "cycloneiiigl") || (device == "Stingray") || (device == "STINGRAY") || (device == "stingray"))
    || ((device == "Cyclone V") || (device == "CYCLONE V") || (device == "cyclone v") || (device == "CycloneV") || (device == "CYCLONEV") || (device == "cyclonev") || (device == "Cyclone V (GT/GX/E/SX)") || (device == "CYCLONE V (GT/GX/E/SX)") || (device == "cyclone v (gt/gx/e/sx)") || (device == "CycloneV(GT/GX/E/SX)") || (device == "CYCLONEV(GT/GX/E/SX)") || (device == "cyclonev(gt/gx/e/sx)") || (device == "Cyclone V (E/GX/GT/SX/SE/ST)") || (device == "CYCLONE V (E/GX/GT/SX/SE/ST)") || (device == "cyclone v (e/gx/gt/sx/se/st)") || (device == "CycloneV(E/GX/GT/SX/SE/ST)") || (device == "CYCLONEV(E/GX/GT/SX/SE/ST)") || (device == "cyclonev(e/gx/gt/sx/se/st)") || (device == "Cyclone V (E)") || (device == "CYCLONE V (E)") || (device == "cyclone v (e)") || (device == "CycloneV(E)") || (device == "CYCLONEV(E)") || (device == "cyclonev(e)") || (device == "Cyclone V (GX)") || (device == "CYCLONE V (GX)") || (device == "cyclone v (gx)") || (device == "CycloneV(GX)") || (device == "CYCLONEV(GX)") || (device == "cyclonev(gx)") || (device == "Cyclone V (GT)") || (device == "CYCLONE V (GT)") || (device == "cyclone v (gt)") || (device == "CycloneV(GT)") || (device == "CYCLONEV(GT)") || (device == "cyclonev(gt)") || (device == "Cyclone V (SX)") || (device == "CYCLONE V (SX)") || (device == "cyclone v (sx)") || (device == "CycloneV(SX)") || (device == "CYCLONEV(SX)") || (device == "cyclonev(sx)") || (device == "Cyclone V (SE)") || (device == "CYCLONE V (SE)") || (device == "cyclone v (se)") || (device == "CycloneV(SE)") || (device == "CYCLONEV(SE)") || (device == "cyclonev(se)") || (device == "Cyclone V (ST)") || (device == "CYCLONE V (ST)") || (device == "cyclone v (st)") || (device == "CycloneV(ST)") || (device == "CYCLONEV(ST)") || (device == "cyclonev(st)"))
    || ((device == "Cyclone") || (device == "CYCLONE") || (device == "cyclone") || (device == "ACEX2K") || (device == "acex2k") || (device == "ACEX 2K") || (device == "acex 2k") || (device == "Tornado") || (device == "TORNADO") || (device == "tornado"))
    || ((device == "HardCopy II") || (device == "HARDCOPY II") || (device == "hardcopy ii") || (device == "HardCopyII") || (device == "HARDCOPYII") || (device == "hardcopyii") || (device == "Fusion") || (device == "FUSION") || (device == "fusion"))
    || ((device == "HardCopy III") || (device == "HARDCOPY III") || (device == "hardcopy iii") || (device == "HardCopyIII") || (device == "HARDCOPYIII") || (device == "hardcopyiii") || (device == "HCX") || (device == "hcx"))
    || ((device == "HardCopy IV") || (device == "HARDCOPY IV") || (device == "hardcopy iv") || (device == "HardCopyIV") || (device == "HARDCOPYIV") || (device == "hardcopyiv") || (device == "HardCopy IV (GX)") || (device == "HARDCOPY IV (GX)") || (device == "hardcopy iv (gx)") || (device == "HardCopy IV (E)") || (device == "HARDCOPY IV (E)") || (device == "hardcopy iv (e)") || (device == "HardCopyIV(GX)") || (device == "HARDCOPYIV(GX)") || (device == "hardcopyiv(gx)") || (device == "HardCopyIV(E)") || (device == "HARDCOPYIV(E)") || (device == "hardcopyiv(e)") || (device == "HCXIV") || (device == "hcxiv") || (device == "HardCopy IV (GX/E)") || (device == "HARDCOPY IV (GX/E)") || (device == "hardcopy iv (gx/e)") || (device == "HardCopy IV (E/GX)") || (device == "HARDCOPY IV (E/GX)") || (device == "hardcopy iv (e/gx)") || (device == "HardCopyIV(GX/E)") || (device == "HARDCOPYIV(GX/E)") || (device == "hardcopyiv(gx/e)") || (device == "HardCopyIV(E/GX)") || (device == "HARDCOPYIV(E/GX)") || (device == "hardcopyiv(e/gx)"))
    || ((device == "MAX II") || (device == "max ii") || (device == "MAXII") || (device == "maxii") || (device == "Tsunami") || (device == "TSUNAMI") || (device == "tsunami"))
    || ((device == "MAX V") || (device == "max v") || (device == "MAXV") || (device == "maxv") || (device == "Jade") || (device == "JADE") || (device == "jade"))
    || ((device == "MAX3000A") || (device == "max3000a") || (device == "MAX 3000A") || (device == "max 3000a"))
    || ((device == "MAX7000AE") || (device == "max7000ae") || (device == "MAX 7000AE") || (device == "max 7000ae"))
    || ((device == "MAX7000B") || (device == "max7000b") || (device == "MAX 7000B") || (device == "max 7000b"))
    || ((device == "MAX7000S") || (device == "max7000s") || (device == "MAX 7000S") || (device == "max 7000s"))
    || ((device == "Stratix GX") || (device == "STRATIX GX") || (device == "stratix gx") || (device == "Stratix-GX") || (device == "STRATIX-GX") || (device == "stratix-gx") || (device == "StratixGX") || (device == "STRATIXGX") || (device == "stratixgx") || (device == "Aurora") || (device == "AURORA") || (device == "aurora"))
    || ((device == "Stratix II GX") || (device == "STRATIX II GX") || (device == "stratix ii gx") || (device == "StratixIIGX") || (device == "STRATIXIIGX") || (device == "stratixiigx"))
    || ((device == "Stratix II") || (device == "STRATIX II") || (device == "stratix ii") || (device == "StratixII") || (device == "STRATIXII") || (device == "stratixii") || (device == "Armstrong") || (device == "ARMSTRONG") || (device == "armstrong"))
    || ((device == "Stratix III") || (device == "STRATIX III") || (device == "stratix iii") || (device == "StratixIII") || (device == "STRATIXIII") || (device == "stratixiii") || (device == "Titan") || (device == "TITAN") || (device == "titan") || (device == "SIII") || (device == "siii"))
    || ((device == "Stratix IV") || (device == "STRATIX IV") || (device == "stratix iv") || (device == "TGX") || (device == "tgx") || (device == "StratixIV") || (device == "STRATIXIV") || (device == "stratixiv") || (device == "Stratix IV (GT)") || (device == "STRATIX IV (GT)") || (device == "stratix iv (gt)") || (device == "Stratix IV (GX)") || (device == "STRATIX IV (GX)") || (device == "stratix iv (gx)") || (device == "Stratix IV (E)") || (device == "STRATIX IV (E)") || (device == "stratix iv (e)") || (device == "StratixIV(GT)") || (device == "STRATIXIV(GT)") || (device == "stratixiv(gt)") || (device == "StratixIV(GX)") || (device == "STRATIXIV(GX)") || (device == "stratixiv(gx)") || (device == "StratixIV(E)") || (device == "STRATIXIV(E)") || (device == "stratixiv(e)") || (device == "StratixIIIGX") || (device == "STRATIXIIIGX") || (device == "stratixiiigx") || (device == "Stratix IV (GT/GX/E)") || (device == "STRATIX IV (GT/GX/E)") || (device == "stratix iv (gt/gx/e)") || (device == "Stratix IV (GT/E/GX)") || (device == "STRATIX IV (GT/E/GX)") || (device == "stratix iv (gt/e/gx)") || (device == "Stratix IV (E/GT/GX)") || (device == "STRATIX IV (E/GT/GX)") || (device == "stratix iv (e/gt/gx)") || (device == "Stratix IV (E/GX/GT)") || (device == "STRATIX IV (E/GX/GT)") || (device == "stratix iv (e/gx/gt)") || (device == "StratixIV(GT/GX/E)") || (device == "STRATIXIV(GT/GX/E)") || (device == "stratixiv(gt/gx/e)") || (device == "StratixIV(GT/E/GX)") || (device == "STRATIXIV(GT/E/GX)") || (device == "stratixiv(gt/e/gx)") || (device == "StratixIV(E/GX/GT)") || (device == "STRATIXIV(E/GX/GT)") || (device == "stratixiv(e/gx/gt)") || (device == "StratixIV(E/GT/GX)") || (device == "STRATIXIV(E/GT/GX)") || (device == "stratixiv(e/gt/gx)") || (device == "Stratix IV (GX/E)") || (device == "STRATIX IV (GX/E)") || (device == "stratix iv (gx/e)") || (device == "StratixIV(GX/E)") || (device == "STRATIXIV(GX/E)") || (device == "stratixiv(gx/e)"))
    || ((device == "Stratix V") || (device == "STRATIX V") || (device == "stratix v") || (device == "StratixV") || (device == "STRATIXV") || (device == "stratixv") || (device == "Stratix V (GS)") || (device == "STRATIX V (GS)") || (device == "stratix v (gs)") || (device == "StratixV(GS)") || (device == "STRATIXV(GS)") || (device == "stratixv(gs)") || (device == "Stratix V (GT)") || (device == "STRATIX V (GT)") || (device == "stratix v (gt)") || (device == "StratixV(GT)") || (device == "STRATIXV(GT)") || (device == "stratixv(gt)") || (device == "Stratix V (GX)") || (device == "STRATIX V (GX)") || (device == "stratix v (gx)") || (device == "StratixV(GX)") || (device == "STRATIXV(GX)") || (device == "stratixv(gx)") || (device == "Stratix V (GS/GX)") || (device == "STRATIX V (GS/GX)") || (device == "stratix v (gs/gx)") || (device == "StratixV(GS/GX)") || (device == "STRATIXV(GS/GX)") || (device == "stratixv(gs/gx)") || (device == "Stratix V (GS/GT)") || (device == "STRATIX V (GS/GT)") || (device == "stratix v (gs/gt)") || (device == "StratixV(GS/GT)") || (device == "STRATIXV(GS/GT)") || (device == "stratixv(gs/gt)") || (device == "Stratix V (GT/GX)") || (device == "STRATIX V (GT/GX)") || (device == "stratix v (gt/gx)") || (device == "StratixV(GT/GX)") || (device == "STRATIXV(GT/GX)") || (device == "stratixv(gt/gx)") || (device == "Stratix V (GX/GS)") || (device == "STRATIX V (GX/GS)") || (device == "stratix v (gx/gs)") || (device == "StratixV(GX/GS)") || (device == "STRATIXV(GX/GS)") || (device == "stratixv(gx/gs)") || (device == "Stratix V (GT/GS)") || (device == "STRATIX V (GT/GS)") || (device == "stratix v (gt/gs)") || (device == "StratixV(GT/GS)") || (device == "STRATIXV(GT/GS)") || (device == "stratixv(gt/gs)") || (device == "Stratix V (GX/GT)") || (device == "STRATIX V (GX/GT)") || (device == "stratix v (gx/gt)") || (device == "StratixV(GX/GT)") || (device == "STRATIXV(GX/GT)") || (device == "stratixv(gx/gt)") || (device == "Stratix V (GS/GT/GX)") || (device == "STRATIX V (GS/GT/GX)") || (device == "stratix v (gs/gt/gx)") || (device == "Stratix V (GS/GX/GT)") || (device == "STRATIX V (GS/GX/GT)") || (device == "stratix v (gs/gx/gt)") || (device == "Stratix V (GT/GS/GX)") || (device == "STRATIX V (GT/GS/GX)") || (device == "stratix v (gt/gs/gx)") || (device == "Stratix V (GT/GX/GS)") || (device == "STRATIX V (GT/GX/GS)") || (device == "stratix v (gt/gx/gs)") || (device == "Stratix V (GX/GS/GT)") || (device == "STRATIX V (GX/GS/GT)") || (device == "stratix v (gx/gs/gt)") || (device == "Stratix V (GX/GT/GS)") || (device == "STRATIX V (GX/GT/GS)") || (device == "stratix v (gx/gt/gs)") || (device == "StratixV(GS/GT/GX)") || (device == "STRATIXV(GS/GT/GX)") || (device == "stratixv(gs/gt/gx)") || (device == "StratixV(GS/GX/GT)") || (device == "STRATIXV(GS/GX/GT)") || (device == "stratixv(gs/gx/gt)") || (device == "StratixV(GT/GS/GX)") || (device == "STRATIXV(GT/GS/GX)") || (device == "stratixv(gt/gs/gx)") || (device == "StratixV(GT/GX/GS)") || (device == "STRATIXV(GT/GX/GS)") || (device == "stratixv(gt/gx/gs)") || (device == "StratixV(GX/GS/GT)") || (device == "STRATIXV(GX/GS/GT)") || (device == "stratixv(gx/gs/gt)") || (device == "StratixV(GX/GT/GS)") || (device == "STRATIXV(GX/GT/GS)") || (device == "stratixv(gx/gt/gs)") || (device == "Stratix V (GS/GT/GX/E)") || (device == "STRATIX V (GS/GT/GX/E)") || (device == "stratix v (gs/gt/gx/e)") || (device == "StratixV(GS/GT/GX/E)") || (device == "STRATIXV(GS/GT/GX/E)") || (device == "stratixv(gs/gt/gx/e)") || (device == "Stratix V (E)") || (device == "STRATIX V (E)") || (device == "stratix v (e)") || (device == "StratixV(E)") || (device == "STRATIXV(E)") || (device == "stratixv(e)"))
    || ((device == "Stratix VI") || (device == "STRATIX VI") || (device == "stratix vi") || (device == "StratixVI") || (device == "STRATIXVI") || (device == "stratixvi") || (device == "Night Fury") || (device == "NIGHT FURY") || (device == "night fury") || (device == "nightfury") || (device == "NIGHTFURY") || (device == "Stratix VI (GS/GX)") || (device == "STRATIX VI (GS/GX)") || (device == "stratix vi (gs/gx)") || (device == "StratixVI(GS/GX)") || (device == "STRATIXVI(GS/GX)") || (device == "stratixvi(gs/gx)") || (device == "Stratix VI (GS)") || (device == "STRATIX VI (GS)") || (device == "stratix vi (gs)") || (device == "StratixVI(GS)") || (device == "STRATIXVI(GS)") || (device == "stratixvi(gs)") || (device == "Stratix VI (GX)") || (device == "STRATIX VI (GX)") || (device == "stratix vi (gx)") || (device == "StratixVI(GX)") || (device == "STRATIXVI(GX)") || (device == "stratixvi(gx)"))
    || ((device == "Stratix") || (device == "STRATIX") || (device == "stratix") || (device == "Yeager") || (device == "YEAGER") || (device == "yeager")))
        is_valid = 1;
    else
        is_valid = 0;

    IS_VALID_FAMILY = is_valid;
end
endfunction // IS_VALID_FAMILY


endmodule // ALTERA_DEVICE_FAMILIES