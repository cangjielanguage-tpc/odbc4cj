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
        var prepareStatement = conn.prepareStatement("drop table if exists test")
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test(data date NOT NULL, datanull date)")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        var date = DateTime.of(
            year: 2023,
            month: 7,
            dayOfMonth: 20,
            hour: 0,
            minute: 0,
            second: 0,
            nanosecond: 0,
        )
        rowCount = prepareStatement.update([SqlDate(date), SqlNullableDate(None)])
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        var arr: Array<SqlDbType> = [SqlDate(date), SqlNullableDate(None)]
        queryResult.next(arr)
        @Assert("SqlDate", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlDate => @Assert(date, v.value)
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlNullableDate", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlNullableDate => @Assert(None, v.value)
            case _ => @Assert("abc", "123")
        }
    }
}
