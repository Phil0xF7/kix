function isInteger(n) {
    return typeof n === "number" && n % 1 === 0;
};

function isString (s) {
    return typeof s === "string";
};

function valueOrUndefinedOrError (value, check) {
    if (typeof value === "undefined" || check(value)) {
        return value;
    } else {
        throw new Error("Not a valid input value: " + value);
    }
};

function Notes() {
    this.baseUrl = "/notes";
};

function Note(id, subject, content){
    this.baseUrl = "/note";
    this.id = valueOrUndefinedOrError(id, isInteger);
    this.subject = valueOrUndefinedOrError(subject, isString);
    this.content = valueOrUndefinedOrError(content, isString);
};

Note.prototype.url = function() {
    if (isInteger(this.id)) {
        return this.baseUrl + "/" + this.id;
    } else {
        return this.baseUrl;
    }
};

Note.prototype.optionStr = function(){
    return '<option value="' + this.id + '">'+ this.id +'</option>'
};

Note.prototype.formatStr = function(){
    var str = "id: " + this.id  + ", subject: " + this.subject + ", content:" + this.content;
    return str;
};

Notes.prototype.updateIdSelection = function(){
    $.ajax({
        url: this.baseUrl,
        dataType: 'json',
        type: 'GET',
        success: function(data){
            var n;
            $("#txt-noteid").html("");
            $(data).each(function(index){
                // var curId = data[index]["id"];
                // $("#txt-noteid").append('<option value="' + curId + '">'+curId+'</option>');
                n = new Note(data[index]["id"], data[index]["subject"], data[index]["content"]);
                $("#txt-noteid").append(n.optionStr());
            });
        }
    });
};

Notes.prototype.fetchAll = function(){
    $.ajax({
        url: this.baseUrl,
        dataType: 'json',
        type: 'GET',
        success: function(data){
            var str = "All Row Data: =======================><br>";
            var n; 
           $(data).each(function(index){
              n = new Note(data[index]["id"], data[index]["subject"], data[index]["content"]);
              str += n.formatStr() + "<br>";
            });
            $("#content").append(str);
        }
    });
};
//
Note.prototype.fetch = function(){
    var _this = this;
    $.ajax({
        url: this.url(),
        dataType: 'json',
        type: 'GET',
        success: function(data){
            _this.subject = data['subject'];
            _this.content = data['content'];
            $("#content").html("<div class='alert alert-info'><strong>GET</strong> id:" + data["id"] + ", " +_this.subject+", "+_this.content+"</div>");
            notes.fetchAll();
            $("#txt-subject").val(_this.subject);
            $("#txt-content").val(_this.content);
        }
    });
};

Note.prototype.create = function(){
    var _this = this;
    $.ajax({
        url: this.url(),
        dataType: 'json',
        type: "PUT",
        data: JSON.stringify({subject: this.subject, content: this.content}),
        success: function(data){
            _this.subject = data['subject'];
            _this.content = data['content'];
            $("#content").html("<div class='alert alert-success'><strong>PUT</strong> id:" + data["id"] + ", " + data['subject']+", "+data['content']+"</div>");
            refresh();
        },
        error: function(e){
            console.log(e.responseText);
        }
    });
};

Note.prototype.update = function(){
    var _this = this;
    $.ajax({
        url: this.url(),
        dataType: 'json',
        type: 'POST',
        data:JSON.stringify({subject: this.subject, content: this.content}),
        success: function(data){
            _this.subject = data['subject'];
            _this.content = data['content'];
            $("#content").html("<div class='alert alert-success'><strong>POST</strong> id:" + data["id"] + ", " + data['subject']+", "+data['content']+"</div>");
            notes.fetchAll();
        },
        error: function(e){
            console.log(e.responseText);
        }
    });
};

Note.prototype.remove = function(){
    $.ajax({
        url: this.url(),
        dataType: 'json',
        type: 'DELETE',
        success: function(data){
            $("#content").html("<div class='alert alert-warning'><strong>DELETE</strong> Content with id: " + id + " deleted.</div>");
            refresh();
        },
        error: function(e){
            console.log(e.responseText);
        }
    });
};

notes = new Notes();
note = new Note();

$("button").addClass("btn btn-primary");

$("#btn-create").click(function(){
    note.subject = $("#txt-subject").val();
    note.content = $("#txt-content").val();
    note.create();
    notes.updateIdSelection();
});

$("#btn-update").click(function(){
    id = $("#txt-noteid").val();
    note.subject = $("#txt-subject").val();
    note.content = $("#txt-content").val();
    note.update(id);
});

$("#btn-delete").click(function(){
    id = $("#txt-noteid").val();
    note.remove(id);
});

$("#txt-noteid").change(function(){
    note.id = parseInt($("#txt-noteid").val());
    note.fetch();
});

function refresh(){
    notes.updateIdSelection();
    notes.fetchAll();
}

$().ready(refresh());

// when hovering over a button, disable the other buttons
$("#btn-create").hover(
  function () {$(":not(#btn-create)").addClass('disabled');},
  function () {$(":not(#btn-create)").removeClass('disabled');}
);

$("#btn-update").hover(
  function () {$(":not(#btn-update)").addClass('disabled');},
  function () {$(":not(#btn-update)").removeClass('disabled');}
);

$("#btn-delete").hover(
  function () {$(":not(#btn-delete)").addClass('disabled');},
  function () {$(":not(#btn-delete)").removeClass('disabled');}
);

