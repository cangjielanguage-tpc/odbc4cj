// EXEC: cjc %import-path %L %l %f
// EXEC: ./main


import std.database.sql.* 
import std.io.*
import std.time.*
import std.regex.*
import odbc4cj.*
import std.unittest.*
import std.unittest.testmacro.*

@When[os == "Windows"]
var str = "myodbc8a.dll"
@When[os != "Windows"]
var str = "libmyodbc8a.so"

main(): Int64 {
    let filterResultTest: OdbcTest = OdbcTest()

    filterResultTest.test001()

    return 0
}

// @Test
public class OdbcTest {
    // @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        // getInfo 为旧 API（仅 OdbcConnection 内部实现 getInfoString），std Connection 接口无法触达，暂不测试
        // var name = conn.getInfo(6, 200)
        // @Assert(str, name)
        // conn.getInfo(116, 2)
        // conn.getInfo(169, 4)
    }
}
