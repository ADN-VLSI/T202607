class human;

  protected string   name;
  rand protected int age;

  constraint c_age {
    age >= 0;
    age < 120;
  }

  function new(input string name, input int age);
    this.name = name;
    this.age  = age;
  endfunction

  virtual function automatic void set_name(input string name);
    this.name = name;
  endfunction

  virtual function automatic string get_name();
    return this.name;
  endfunction

  virtual function automatic void set_age(input int age);
    if (age > 120) begin
      $display("MashaAllah: %0d", age);
      this.age = age;
    end else if (age >= 0) begin
      this.age = age;
    end else begin
      $display("HOW??? %0d", age);
    end
  endfunction

  virtual function automatic int get_age();
    return this.age;
  endfunction

  virtual function automatic string to_string();
    return $sformatf("Name: %s \033[15GAge: %0d", get_name(), get_age());
  endfunction

  virtual function automatic void display();
    $display(to_string());
  endfunction

endclass

class student extends human;

  string school;
  rand int unsigned roll;

  constraint c_roll {
    roll >= 100;
    roll < 200;
    (roll % 5) == 0;
  }

  function new(input string name, input int age, input string school, input int unsigned roll);
    super.new(name, age);
    this.school = school;
    this.roll   = roll;
  endfunction

  virtual function automatic string to_string();
    string txt;
    $sformat(txt, "%s\033[30GSchool: %s\033[60GRoll: %0d", super.to_string(), this.school,
             this.roll);
    return txt;
  endfunction

endclass

class employee extends human;

  string company;
  rand int unsigned emp_id;

  constraint c_emp_id {
    emp_id >= 1000;
    emp_id < 2000;
    (emp_id % 2) == 1;
  }

  function new(input string name, input int age, input string company, input int unsigned emp_id);
    super.new(name, age);
    this.company = company;
    this.emp_id  = emp_id;
  endfunction

  virtual function automatic string to_string();
    string txt;
    $sformat(txt, "%s\033[30GCompany: %s\033[60GEmp ID: %0d", super.to_string(), this.company,
             this.emp_id);
    return txt;
  endfunction

endclass




module class_test;


  initial begin
    student h1;
    employee h2;

    human h[2];

    h1   = new("Alice", 30, "SchoolA", 1);
    h2   = new("Bob", 25, "SchoolB", 2);

    h[0] = h1;
    h[1] = h2;

    h[0].display();
    h[1].display();

    h[0].randomize();
    h[1].randomize();

    h[0].display();
    h[1].display();

    $finish();

  end

endmodule
