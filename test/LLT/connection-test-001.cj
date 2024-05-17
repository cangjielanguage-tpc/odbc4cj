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
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123456")
        try {
            var conn = database.connect()
            conn.prepareStatement("drop table if exists test_llt")
        } catch (e: SqlException) {
            @Assert(e.message.startsWith("HY000, SqlState: [unixODBC][MySQL][ODBC 8.0(a) Driver]Access denied for user 'root'"))
            @Assert(e.message.endsWith("' (using password: YES), errorCode: 1045"))

            database = driver.open("DATABASE=mysql;UID=root;PWD=123")
            var conn = database.connect()

            conn.state
            conn.isClosed()
            conn.close()
            conn.close()
        }
    }
}
