// EXEC: cjc %import-path %L %l %f
// EXEC: ./main

package odbc
from std import database.sql.*, io.*, time.*, regex.*
from odbc4cj import odbc.*
from std import unittest.*
from std import unittest.testmacro.*

main(): Int64 {
    let filterResultTest: OdbcTest = OdbcTest()

    filterResultTest.test001()

    return 0
}

@Test
public class OdbcTest {
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var name = conn.getInfo(6, 200)
        @Assert("libmyodbc8a.so", name)
        conn.getInfo(116, 2)
        conn.getInfo(169, 4)
        try {
            conn.getInfo(135, 8)
        } catch (e: SqlException) {
            @Assert("SQLGetInfo failed.", e.message)
        }
    }
}
