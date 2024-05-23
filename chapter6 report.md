第六章实验报告

# 串行内积运算器

## 补全代码

```verilog
module serial_pe(
  input                clk,
  input                rst_n,
  input  signed [15:0] neuron,
  input  signed [15:0] weight,
  input         [ 1:0] ctl,
  input                vld_i,
  output        [31:0] result,
  output reg           vld_o
);

/*乘法器*/  /*TODO*/
wire signed [31:0] mult_res = neuron * weight;
reg [31:0] psum_r;

/*加法器*/  /*TODO*/
wire [31:0] psum_d = psum_r + mult_res;

/*部分和寄存器*/
always@(posedge clk or negedge rst_n)
if(!rst_n) begin
  psum_r <= 32'h0;
end else if(vld_i) begin
  psum_r <= ctrl[0] ? mult_res : psum_d;
end

always@(posedge clk or negedge rst_n)
if(!rst_n) begin
  vld_o <= 1'b0;
end else if(ctrl[1] & vld_i) begin
  vld_o <= 1'b1;
end else begin
  vld_o <= 1'b0;
end

assign result = psum_r;

endmodule
```



```verilog
wire signed [31:0] mult_res = neuron * weight;
```

就用简单的乘法就行。

```verilog
  psum_r <= ctrl[0] ? mult_res : psum_d;
```

`ctrl[0]`表示第一个元素，如果为真，直接打入运算结果，不需要累加。

```verilog
end else if(ctrl[1] & vld_i) begin
  vld_o <= 1'b1;
```

`ctrL[1]`表示最后一个元素，如果为真并且有效，则下个周期把`vl_o`信号置为真，表示运算结束。

## 测试代码

写了一个简单的testbench

```verilog
`timescale 1ns / 1ps

module tb;

// Inputs
reg clk;
reg rst_n;
reg signed [15:0] neuron;
reg signed [15:0] weight;
reg [1:0] ctl;
reg vld_i;

// Outputs
wire [31:0] result;
wire vld_o;

// Instantiate the module under test
serial_pe uut (
    .clk(clk),
    .rst_n(rst_n),
    .neuron(neuron),
    .weight(weight),
    .ctl(ctl),
    .vld_i(vld_i),
    .result(result),
    .vld_o(vld_o)
);

// Test stimulus
initial begin
    // Dumping VCD file
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);

    clk = 0;
    rst_n = 0;
    neuron = 16'd5;
    weight = 16'd3;
    ctl = 2'b00;
    vld_i = 0;
    
    #10; // Allow one clock cycle for reset to settle
    rst_n = 1;
    
    // Test case 1: Basic multiplication and addition
    vld_i = 1;
    ctl = 2'b01;
    #10; // Wait for one clock cycle
    $display("Result: %h, vld_o: %b", result, vld_o);

    // Test case 2: Control signal for bypassing addition (ctl[0])
    ctl = 2'b00;
    #10; // Wait for one clock cycle
    $display("Result: %h, vld_o: %b", result, vld_o);

    // Test case 3: Control signal for enabling vld_o (ctl[1])
    ctl = 2'b10;
    vld_i = 1;
    #10; // Wait for one clock cycle
    $display("Result: %h, vld_o: %b", result, vld_o);

    // Terminate the simulation
    $finish;
end

// Clock generation
always #5 clk = ~clk;

endmodule
```

测试代码连续3个周期进行3*5运算，然后累加。

波形图如下：

![image-20240515142803605](https://raw.githubusercontent.com/DavidZyy/img_bed_2/main/images/image-20240515142803605.png)

结果如下：

![image-20240515142912383](https://raw.githubusercontent.com/DavidZyy/img_bed_2/main/images/image-20240515142912383.png)

最终结果正确。

使用给出的顶层模块和数据进行了多次的测试，测试结果如下：

![image-20240523153946924](https://raw.githubusercontent.com/DavidZyy/img_bed_2/main/images/image-20240523153946924.png)

![image-20240523154052761](https://raw.githubusercontent.com/DavidZyy/img_bed_2/main/images/image-20240523154052761.png)

![image-20240523154118895](https://raw.githubusercontent.com/DavidZyy/img_bed_2/main/images/image-20240523154118895.png)



由图可见，测试结果正确。

波形图如下：

![image-20240523160241949](https://raw.githubusercontent.com/DavidZyy/img_bed_2/main/images/image-20240523160241949.png)

# 并行内积运算器

## 补全代码

### 并行乘法器

```verilog
genvar i;
wire signed [15:0] int16_neuron[31:0];
wire signed [15:0] int16_weight[31:0];
wire signed [31:0] int16_mult_result[31:0];
generate
  for(i=0; i<32; i=i+1)
  begin:int16_mult                 /* TODO */
    assing int16_neuron[i] = mult_neuron[16*i+15 : 16*i];
    assign int16_weight[i] = mult_weight[16*i+15 : 16*i];
    assign int16_mult_result[i] = int16_neuron[i] * int16_weight[i];
  end
endgenerate
```

分别把neuron和weight分为32个16位数，然后相乘得到32个32位数。最终得到结果，赋值给`mult_result`。



### 累加器

| 数量 | 层数 |
| ---- | ---- |
| 1    | 5    |
| 2    | 4    |
| 4    | 3    |
| 8    | 2    |
| 16   | 1    |
| 32   | 0    |

补全累加代码

```verilog
wire [31:0] int16_result[5:0][31:0];
for(i=0; i<=5; i=i+1)
begin:int16_add_tree
  for(j=0; j<(32/(2**i)); j=j+1)
  begin:int16_adder
    if(i==0) begin
      assign int16_result[0][j] = mult_result[32*j+31 : 32*j];
    end else begin
      assign int16_result[i][j] = int16_result[i-1][2*j] + int16_result[i-1][2*j+1];
    end
  end
end
```

第一处把`mult_result`分为最底层的32位的32个数。

第二处把下一层的两个数相加，得到本层的数。

### 顶层模块

和串行内积运算器一样。

```verilog
wire [31:0] psum_d = {32{~ctl[0]}} & psum_r + acc_result;
```

当`ctl[0]`为1，表示第一个数据，则 `{32{~ctl[0]}} & psum_r`将后者清零，只会加上`acc_result`。

## 仿真测试

一共进行了3组测试，结果都通过了，如下截图所示：

![image-20240523154343694](https://raw.githubusercontent.com/DavidZyy/img_bed_2/main/images/image-20240523154343694.png)



![image-20240523154404406](https://raw.githubusercontent.com/DavidZyy/img_bed_2/main/images/image-20240523154404406.png)



![image-20240523154432842](https://raw.githubusercontent.com/DavidZyy/img_bed_2/main/images/image-20240523154432842.png)

波形文件

![image-20240516101838126](https://raw.githubusercontent.com/DavidZyy/img_bed_2/main/images/image-20240516101838126.png)

![image-20240523160310306](https://raw.githubusercontent.com/DavidZyy/img_bed_2/main/images/image-20240523160310306.png)

# 矩阵运算子单元

## 补全代码

矩阵运算的底层是并行内积运算器，可以复用实验2的代码。

顶层模块代码：

```verilog
always@(posedge clk or negedge rst_n) begin
/* TODO: inst_vld & inst */
  if(!rst_n) begin
    inst_vld <= 1'b0;
    inst <= 8'h0;
  end else if(ib_ctl_uop_valid && ib_ctl_uop_ready) begin
    inst_vld <= 1'b1;
    inst <= ib_ctl_uop;
  end else if((!ib_ctl_uop_valid) && ib_ctl_uop_ready) begin
    inst_vld <= 1'b0;
  end
end
```

当控制信号valid并且ready的时候打入相应的寄存器。当valid为低电平的时候，`inst_vld`也拉低。

```verilog
always@(posedge clk or negedge rst_n) begin
  /* TODO: iter */
  if(!rst_n) begin
    iter <= 8'b0;
  end else if(ib_ctl_uop_valid && ib_ctl_uop_ready) begin
    iter <= 8'b0;
  end else if(pe_vld_i) begin
    iter <= iter + 1'b1;
  end
end
```

当valid并且ready时，iter置为0，当`pre_vld_i`为高电平时，每个时钟周期`iter`增加1。

```verilog
always@(posedge clk or negedge rst_n) begin
  /* TODO: ib_ctl_uop_ready */
  if(!rst_n) begin
    ib_ctl_uop_ready <= 1'b1;
  end else if((iter == (inst - 1'b1)) && pe_vld_i) begin
    ib_ctl_uop_ready <= 1'b1;
  end else if(ib_ctl_uop_valid) begin
    ib_ctl_uop_ready <= 1'b0;
  end
end
```

当 `(iter == (inst - 1'b1)) && pe_vld_i`说明运算结束，可以接受新的数据，下个时钟将 `ib_ctl_uop_ready`置为1，然后再下个时钟恢复为0.

```verilog
assign pe_ctl[0] = (iter[7:0] == 8'h0);  /* TODO */
assign pe_ctl[1] = (iter[7:0] == (inst[7:0] - 1'b1)); /* TODO */
```

在第一个和最后一个数据的时候，分别拉高相应的信号。

```verilog
parallel_pe u_parallel_pe (
  .clk                  (clk      ),
  .rst_n                (rst_n    ),
  .neuron               (pe_neuron),
  .weight               (pe_weight),
  .ctl                  (pe_ctl   ),
  .vld_i                (pe_vld_i ),
  .result               (pe_result),
  .vld_o                (pe_vld_o )
);
```

实例化模块。

```verilog
assign nram_mpe_neuron_ready = inst_vld && wram_mpe_weight_valid;  /* TODO */
assign wram_mpe_weight_ready = inst_vld && nram_mpe_neuron_valid;  /* TODO */
```

拉高相应的`ready`信号。

## 仿真测试

进行了3组测试，都通过了。

![image-20240523161328081](https://raw.githubusercontent.com/DavidZyy/img_bed_2/main/images/image-20240523161328081.png)

![image-20240523161354681](https://raw.githubusercontent.com/DavidZyy/img_bed_2/main/images/image-20240523161354681.png)

![image-20240523161410730](https://raw.githubusercontent.com/DavidZyy/img_bed_2/main/images/image-20240523161410730.png)



波形文件如下：

![image-20240523160346033](https://raw.githubusercontent.com/DavidZyy/img_bed_2/main/images/image-20240523160346033.png)

![image-20240523161437352](https://raw.githubusercontent.com/DavidZyy/img_bed_2/main/images/image-20240523161437352.png)

# 工程说明

本次实验在linux平台上进行，使用了开源工具iverilog和gtkwave进行仿真和测试。

为此编写了Makefile自动化脚本，如下：

```makefile
TESTBENCHFILE = tb_top_0.v
TEST = $(basename $(TESTBENCHFILE))

run:
	iverilog $(TESTBENCHFILE) -y . -o $(TEST)
	vvp -n $(TEST) -vcd

wave:
	gtkwave $(TEST).vcd 

clean:
	rm $(TEST) $(TEST).vcd

```

可以使用`make run`进行编译和运行，生成波形文件。

使用`make wave`查看波形。

使用`make clean`清除编译文件。

自动化脚本的部署大大加快了实验的仿真和验证流程，提高了工作效率。