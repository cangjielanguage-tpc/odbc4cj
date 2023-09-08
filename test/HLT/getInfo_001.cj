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
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var name = conn.getInfo(6, 200)
        @Assert("libmyodbc8a.so", name)
        conn.getInfo(116, 2)
        conn.getInfo(169, 4)
        try {
            conn.getInfo(135, 8)
        } catch (e: SqlException) {
            @Assert("HYC00, SqlState: [MySQL][ODBC 8.0(a) Driver]Unsupported option: 135 to SQLGetInfo, errorCode: 4000", e.message)
        }
    }
}
