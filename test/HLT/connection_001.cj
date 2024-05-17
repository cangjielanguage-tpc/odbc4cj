//3rd_party_lib:odbc4cj/build/odbc4cj

from std import database.sql.*, io.*, time.*, regex.*
from odbc4cj import odbc.*

@Test
public class OdbcTest {
    init() {
    }
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123456")
        try {
            var conn = database.connect()
            conn.prepareStatement("drop table if exists test")
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
