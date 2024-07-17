//3rd_party_lib:odbc4cj/build/odbc4cj

import std.database.sql.* 
import std.io.*
import std.time.*
import std.regex.*
import odbc4cj.*

@When[os == "Windows"]
var str = "myodbc8a.dll"
@When[os != "Windows"]
var str = "libmyodbc8a.so"

@Test
public class OdbcTest {
    init() {
    }
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var name = conn.getInfo(6, 200)
        @Assert(str, name)
        conn.getInfo(116, 2)
        conn.getInfo(169, 4)
    }
}
