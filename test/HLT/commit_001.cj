//3rd_party_lib:odbc4cj/build/odbc4cj

from std import database.sql.*, io.*, time.*, regex.*, math.*
from odbc4cj import odbc.*

@Test
public class OdbcTest {
    init() {
    }
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123", [("SQL_ATTR_AUTOCOMMIT", "SQL_AUTOCOMMIT_OFF")])
        var conn = database.connect()
        var tran = conn.createTransaction()
        tran.begin()
        var prepareStatement = conn.prepareStatement("drop table if exists test")
        var rowCount = prepareStatement.update()
        tran.commit()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test(data int NOT NULL, datanull int)")
        rowCount = prepareStatement.update()
        tran.commit()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        rowCount = prepareStatement.update([SqlInteger(Int32.Max), SqlNullableInteger(None)])
        rowCount = prepareStatement.update([SqlInteger(Int32.Max), SqlNullableInteger(None)])
        tran.commit()
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        var arr: Array<SqlDbType> = [SqlInteger(Int32.Max), SqlNullableInteger(None)]
        tran.commit()
        queryResult.next(arr)
        tran.commit()
        @Assert("SqlInteger", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlInteger => @Assert(Int32.Max, v.value)
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlNullableInteger", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlNullableInteger => @Assert(None, v.value)
            case _ => @Assert("abc", "123")
        }

        prepareStatement = conn.prepareStatement("update test set datanull = 10")
        rowCount = prepareStatement.update()
        @Assert(2, rowCount.rowCount)
        tran.commit()
    }
}
