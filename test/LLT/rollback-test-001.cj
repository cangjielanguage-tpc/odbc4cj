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
        prepareStatement = conn.prepareStatement("insert into test values(123,123)")
        tran.rollback()

        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        rowCount = prepareStatement.update([SqlIntger(456), SqlNullableIntger(None)])
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        var arr: Array<SqlDbType> = queryResult.getSqlDbType()
        queryResult.next(arr)
        tran.commit()
        @Assert("SqlIntger", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlIntger => @Assert(456, v.value)
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlNullableIntger", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlNullableIntger => @Assert(None, v.value)
            case _ => @Assert("abc", "123")
        }
    }
}
