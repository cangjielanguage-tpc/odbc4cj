// EXEC: cjc %import-path %L %l %f
// EXEC: ./main

package odbc
from std import database.sql.*, io.*, time.*, regex.*, math.*
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
        var prepareStatement = conn.prepareStatement("drop table if exists test")
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test(data TINYINT NOT NULL, datanull TINYINT)")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        rowCount = prepareStatement.update([SqlByte(Int8.Max), SqlNullableByte(None)])
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        var arr: Array<SqlDbType> = queryResult.getSqlDbType()
        queryResult.next(arr)
        @Assert("SqlByte", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlByte => @Assert(Int8.Max, v.value)
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlNullableByte", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlNullableByte => @Assert(None, v.value)
            case _ => @Assert("abc", "123")
        }
    }
}
