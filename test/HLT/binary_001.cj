//3rd_party_lib:odbc4cj/build/odbc4cj

from std import database.sql.*, io.*, time.*, regex.*
from odbc4cj import odbc.*

@Test
public class binary_001 {
    var conn: OdbcConnection
    var prepareStatement: OdbcStatement
    var rowCount: OdbcUpdateResult
    init(){
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        conn = database.connect()
        prepareStatement = conn.prepareStatement("drop table if exists test")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test(data BINARY(20) NOT NULL, datanull BINARY(20))")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
    }

    @TestCase
    public func test001(): Unit {
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        rowCount = prepareStatement.update([SqlBinary([0,22]), SqlNullableBinary(None)])
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        var arr: Array<SqlDbType> = [SqlBinary([0,11]), SqlNullableBinary(None)]
        queryResult.next(arr)
        @Assert("SqlBinary", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlBinary => @Assert(true, v.value[..2]==[0, 22])
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlNullableBinary", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlNullableBinary => @Assert(None, v.value)
            case _ => @Assert("abc", "123")
        }
    }
}
